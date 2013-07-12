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
          key = storage.send(:cache_key_for, cache_request)
          if storage.cache.exist?(key)
            return storage.cache.read(key)
          else
            ld_obj = LinkedData::Client::HTTP.object_from_json(requested_env[:body])
            storage.cache.write(key, ld_obj)
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
