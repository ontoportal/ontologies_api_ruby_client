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
          key = storage.send(:cache_key_for, cache_request)
          if storage.cache.exist?(key)
            stored_obj = storage.cache.read(key).dup
            # Update if last modified is different
            if stored_obj[:last_modified] != last_modified
              puts "UPDATING CACHE #{requested_env[:url].to_s}"
              stored_obj[:last_modified] = last_modified
              storage.cache.write(key, stored_obj)
            end
            return stored_obj[:ld_obj]
          else
            ld_obj = LinkedData::Client::HTTP.object_from_json(requested_env[:body])
            stored_obj = {last_modified: last_modified, ld_obj: ld_obj}
            storage.cache.write(key, stored_obj)
            return ld_obj
          end
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
