require 'digest/sha1'
require 'active_support/cache'
require_relative '../http'

module Faraday
  ##
  # This middleware causes Faraday to return 
  class ObjectCache < Faraday::Middleware
    def initialize(app, *arguments)
      super(app)
      
      if arguments.last.is_a? Hash
        options = arguments.pop
        @logger = options.delete(:logger)
      else
        options = arguments
      end
      
      @store = options[:store] || ActiveSupport::Cache.lookup_store(store, options)
    end
    
    def call(env)
      @app.call(env).on_complete do |requested_env|
        if [:get, :head].include?(requested_env[:method])
          cache_request = @app.send(:create_request, requested_env)
          last_modified = requested_env[:response_headers]["Last-Modified"]
          # Alter the cache request object for storing our parsed objects
          cache_request[:object_cached] = true
          # Access storage's private key generation method
          key = cache_key_for(cache_request)
          if @store.exist?(key)
            stored_obj = @store.read(key)

            # Update if last modified is different
            if stored_obj[:last_modified] != last_modified
              puts "UPDATING CACHE #{requested_env[:url].to_s}" if $DEBUG
              stored_obj[:last_modified] = last_modified
              @store.write(key, stored_obj)
            end
            
            # If we have a string, we must have had to serialize to JSON to avoid Marshal failures (see below)
            if stored_obj[:ld_obj].is_a?(String) && !stored_obj[:ld_obj].empty?
              stored_obj[:ld_obj] = MultiJson.load(stored_obj[:ld_obj]) rescue binding.pry
            end
            
            ld_obj = stored_obj[:ld_obj]
          else
            ld_obj = LinkedData::Client::HTTP.object_from_json(requested_env[:body])
            unless ld_obj.is_a?(Struct)
              puts "STORING OBJECT: #{requested_env[:url].to_s}" if $DEBUG
              stored_obj = {last_modified: last_modified, ld_obj: ld_obj}
              @store.write(key, stored_obj) rescue binding.pry
            end
          end

          return ld_obj
        end
      end
    end
    
    private
    
    # Internal: Generates a String key for a given request object.
    # The request object is folded into a sorted Array (since we can't count
    # on hashes order on Ruby 1.8), encoded as JSON and digested as a `SHA1`
    # string.
    #
    # Returns the encoded String.
    def cache_key_for(request)
      array = request.stringify_keys.to_a.sort
      Digest::SHA1.hexdigest(Marshal.dump(array))
    end
  end
end

if Faraday.respond_to?(:register_middleware)
  Faraday.register_middleware object_cache: Faraday::ObjectCache
elsif Faraday::Middleware.respond_to?(:register_middleware)
  Faraday::Middleware.register_middleware object_cache: Faraday::ObjectCache
end
