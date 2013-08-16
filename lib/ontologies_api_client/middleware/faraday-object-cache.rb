require_relative '../http'

module Faraday
  ##
  # This middleware causes Faraday to return 
  class ObjectCache < Faraday::Middleware
    def initialize(app, *arguments)
      super(app)
    end
    
    def call(env)
      dup.call!(env)
    end
    
    def call!(env)
      @app.call(env).on_complete do |requested_env|
        if [:get, :head].include?(requested_env[:method])
          cache_request = @app.send(:create_request, requested_env)
          storage = @app.instance_variable_get("@storage")
          # Alter the cache request object for storing our parsed objects
          cache_request[:object_cached] = true
          last_modified = requested_env[:response_headers]["Last-Modified"]
          # Access storage's private key generation method
          key = storage.send(:cache_key_for, cache_request)
          if storage.cache.exist?(key)
            stored_obj = storage.cache.read(key).dup

            # Update if last modified is different
            if stored_obj[:last_modified] != last_modified
              puts "UPDATING CACHE #{requested_env[:url].to_s}"
              stored_obj[:last_modified] = last_modified
              storage.cache.write(key, stored_obj)
            end
            
            # If we have a string, we must have had to serialize to JSON to avoid Marshal failures (see below)
            if stored_obj[:ld_obj].is_a?(String)
              stored_obj[:ld_obj] = MultiJson.load(stored_obj[:ld_obj])
            end
            
            ld_obj = stored_obj[:ld_obj]
          else
            # We were encountering a weird error where responses with 304 weren't in
            # the cache, so to prevent a failure if we have a 304 but end up here
            # we are going to re-trigger the request
            if requested_env[:status] == 304
              puts "RETRYING QUERY (cache missed but we got a 304) #{requested_env[:url].to_s}"
              env[:request_headers]["If-Modified-Since"] = nil
              requested_env = @app.call(env)
            end
            
            ld_obj = LinkedData::Client::HTTP.object_from_json(requested_env[:body])
            puts "STORING OBJECT: #{requested_env[:url].to_s}"
            stored_obj = {last_modified: last_modified, ld_obj: ld_obj}

            begin
              storage.cache.write(key, stored_obj)
            rescue TypeError
              # Could not serialize the ld_obj with Marshal (probably because it's a struct),
              # convert to JSON string instead
              stored_obj[:ld_obj] = MultiJson.dump(ld_obj)
              storage.cache.write(key, stored_obj)
            end
          end

          return ld_obj
        end
      end
    end
  end
end

if Faraday.respond_to?(:register_middleware)
  Faraday.register_middleware object_cache: Faraday::ObjectCache
elsif Faraday::Middleware.respond_to?(:register_middleware)
  Faraday::Middleware.register_middleware object_cache: Faraday::ObjectCache
end
