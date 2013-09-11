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
          last_modified = requested_env[:response_headers]["Last-Modified"]
          # Alter the cache request object for storing our parsed objects
          cache_request[:object_cached] = true
          # Access storage's private key generation method
          key = storage.send(:cache_key_for, cache_request)
          if storage.cache.exist?(key)
            stored_obj = storage.cache.read(key).dup

            # Update if last modified is different
            if stored_obj[:last_modified] != last_modified
              puts "UPDATING CACHE #{requested_env[:url].to_s}" if $DEBUG
              stored_obj[:last_modified] = last_modified
              storage.cache.write(key, stored_obj)
            end
            
            # If we have a string, we must have had to serialize to JSON to avoid Marshal failures (see below)
            if stored_obj[:ld_obj].is_a?(String) && !stored_obj[:ld_obj].empty?
              stored_obj[:ld_obj] = MultiJson.load(stored_obj[:ld_obj])
            end
            
            ld_obj = stored_obj[:ld_obj]
          else
            ld_obj = LinkedData::Client::HTTP.object_from_json(requested_env[:body])
            puts "STORING OBJECT: #{requested_env[:url].to_s}" if $DEBUG
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
