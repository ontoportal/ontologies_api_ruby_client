require 'digest/sha1'
require 'active_support'
require 'active_support/cache'
require 'lz4_flex'
require_relative '../http'

module Faraday
  class ObjectCacheResponse < Faraday::Response
    attr_accessor :parsed_body
  end

  class ObjectCache < Faraday::Middleware
    def initialize(app, *arguments)
      super(app)
      options = arguments.last.is_a?(Hash) ? arguments.pop : {}
      @logger = options.delete(:logger)
      @store = options[:store] || ActiveSupport::Cache.lookup_store(nil, options)
    end


    def last_modified_key_id(request_key)
      "LM::#{request_key}"
    end

    def last_retrieved_key_id(request_key)
      "LR::#{request_key}"
    end

    def call(env)
      invalidate_cache = env[:request_headers].delete(:invalidate_cache)

      request_key = cache_key_for(create_request(env))
      last_modified_key = last_modified_key_id(request_key)
      last_retrieved_key = last_retrieved_key_id(request_key)

      if invalidate_cache
        delete_cache_entries(request_key, last_modified_key, last_retrieved_key)
        env[:request_headers]["Cache-Control"] = "no-cache"
        puts "Invalidated key #{request_key}" if enable_debug(request_key)
      end

      if cache_exist?(last_retrieved_key) && cache_exist?(request_key)
        puts "Not expired: #{env[:url].to_s}, key #{request_key}" if enable_debug(request_key)
        return retrieve_cached_response(request_key)
      end

      headers = env[:request_headers]
      headers['If-Modified-Since'] = cache_read(last_modified_key) if cache_read(last_modified_key)

      @app.call(env).on_complete do |response_env|
        if [:get, :head].include?(response_env[:method])
          response = process_response(response_env, request_key)
          return response
        end
      end
    end

    private

    def enable_debug(key)
      LinkedData::Client.settings.debug_client && (LinkedData::Client.settings.debug_client_keys.empty? || LinkedData::Client.settings.debug_client_keys.include?(key))
    end

    def delete_cache_entries(*keys)
      keys.each { |key| cache_delete(key) }
    end

    def retrieve_cached_response(request_key)
      cached_item = cache_read(request_key)
      ld_obj = cached_item.is_a?(Hash) && cached_item.key?(:ld_obj) ? cached_item[:ld_obj] : cached_item
      env = { status: 304 }
      cached_response = ObjectCacheResponse.new(env)
      cached_response.parsed_body = ld_obj
      cached_response.env.response_headers = { "X-Rack-Cache" => 'hit' }
      cached_response
    end

    def process_response(response_env, request_key)
      last_modified = response_env[:response_headers]["Last-Modified"]
      key = request_key
      cache_state = "miss"

      if response_env[:status] == 304 && cache_exist?(key)
        cache_state = "fresh"
        ld_obj = update_cache(request_key, last_modified)
      else
        ld_obj = cache_response(response_env, request_key)
      end

      response = ObjectCacheResponse.new(response_env)
      response.parsed_body = ld_obj
      response.env.response_headers["X-Rack-Cache"] = cache_state
      response
    end

    def update_cache(request_key, last_modified)
      stored_obj = cache_read(request_key)
      if stored_obj[:last_modified] != last_modified
        stored_obj[:last_modified] = last_modified
        cache_write(last_modified_key_id(request_key), last_modified)
        cache_write(request_key, stored_obj)
      end
      stored_obj.is_a?(Hash) && stored_obj.key?(:ld_obj) ? stored_obj[:ld_obj] : stored_obj
    end

    def cache_response(response_env, request_key)
      last_modified = response_env[:response_headers]["Last-Modified"]

      if response_env[:body].nil? || response_env[:body].empty?
        # We got here with an empty body, meaning the object wasn't
        # in the cache (weird). So re-do the request.
        puts "REDOING REQUEST, NO CACHE ENTRY for #{response_env[:url].to_s}, key #{request_key}" if enable_debug(request_key)
        response_env[:request_headers].delete("If-Modified-Since")

        response_env = @app.call(response_env).env
        puts "REDOING REQUEST expiry: #{response_env[:response_headers]["Cache-Control"]}, last_modified: #{last_modified} for key #{request_key}" if enable_debug(request_key)
      end


      return nil if response_env[:body].nil? || response_env[:body].empty?

      ld_obj = LinkedData::Client::HTTP.object_from_json(response_env[:body])

      expiry = response_env[:response_headers]["Cache-Control"].to_s.split("max-age=").last.to_i

      if expiry > 0 && last_modified
        store_cache(request_key, ld_obj, last_modified, expiry)
      end

      ld_obj
    end

    def store_cache(request_key, ld_obj, last_modified, expiry)
      stored_obj = { last_modified: last_modified, ld_obj: ld_obj }
      cache_write(last_modified_key_id(request_key), last_modified)
      cache_write(last_retrieved_key_id(request_key), true, expires_in: expiry)
      cache_write(request_key, stored_obj)
    end

    def cache_write(key, obj, *args)
      begin
        result = @store.write(key, obj, *args)
      rescue
        puts "Key too large for cache_write: #{key}" if enable_debug(key)
        result = nil
      end

      if result
        return result
      else
        @large_object_cache ||= {}
        @large_object_cache[key] = obj
        cache_write_compressed(key, obj, *args)
        return true
      end
    end

    def cache_read(key)
      obj = @store.read(key)
      return unless obj

      if obj.is_a?(CompressedMemcache)
        large_obj = @large_object_cache[key] if @large_object_cache
        large_obj ||= cache_read_compressed(key)
        obj = large_obj
      end
      obj.dup
    end

    def cache_exist?(key)
      @store.exist?(key)
    end

    class CompressedMemcache
      attr_accessor :key
    end

    def cache_write_compressed(key, obj, *args)
      # Keep the size-prefixed block format used by existing cache entries
      compressed = Lz4Flex::VarInt.compress(Marshal.dump(obj))

      placeholder = CompressedMemcache.new
      placeholder.key = "#{key}::#{(Time.now.to_f * 1000).to_i}::LZ4"
      begin
        @store.write(key, placeholder)
        @store.write(placeholder.key, compressed)
      rescue
        puts "Key that failed to cache in cache_write_compressed: #{key}" if enable_debug(key)
        @store.delete(key)
        @store.delete(placeholder.key)
      end
    end

    def cache_read_compressed(key)
      obj = @store.read(key)
      if obj.is_a?(CompressedMemcache)
        begin
          uncompressed = Lz4Flex::VarInt.decompress(@store.read(obj.key))
          obj = Marshal.load(uncompressed)
        rescue StandardError => e
          @store.delete(key)
          @store.delete(obj.key)
          raise e
        end
      end
      obj
    end

    def cache_delete(key)
      @store.delete(key)
    end

    def cache_key_for(request)
      array = request.stringify_keys.to_a.sort
      Digest::SHA1.hexdigest(Marshal.dump(array))
    end

    def create_request(env)
      request = env.to_hash.slice(:method, :url, :request_headers)
      request[:request_headers] = request[:request_headers].dup
      request
    end
  end
end

if Faraday.respond_to?(:register_middleware)
  Faraday.register_middleware object_cache: Faraday::ObjectCache
elsif Faraday::Middleware.respond_to?(:register_middleware)
  Faraday::Middleware.register_middleware object_cache: Faraday::ObjectCache
end
