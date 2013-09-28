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
      # Add if newer than last modified statement to headers
      request_key = cache_key_for(create_request(env))
      last_modified_key = "LM::#{request_key}"
      last_retrieved_key = "LR::#{request_key}"
      
      # If we made the last request within the expiry
      if cache_exist?(last_retrieved_key) && cache_exist?(request_key)
        puts "DEBUG not expired" if $DEBUG
        return cache_read(request_key)[:ld_obj]
      end
      
      last_modified = cache_read(last_modified_key)
      headers = env[:request_headers]
      puts "DEBUG " + last_modified.to_s if $DEBUG
      headers['If-Modified-Since'] = last_modified if last_modified
      
      @app.call(env).on_complete do |requested_env|
        # Only cache get and head requests
        if [:get, :head].include?(requested_env[:method])
          puts "DEBUG response status: " + requested_env[:status].to_s if $DEBUG

          last_modified = requested_env[:response_headers]["Last-Modified"]

          # Generate key using header hash
          key = request_key
          
          # If the last retrieve time is less than expiry
          if requested_env[:status] == 304 && cache_exist?(key)
            stored_obj = cache_read(key)
            
            # Update if last modified is different
            stored_obj[:last_modified] != last_modified rescue binding.pry
            if stored_obj[:last_modified] != last_modified
              puts "UPDATING CACHE #{requested_env[:url].to_s}" if $DEBUG
              stored_obj[:last_modified] = last_modified
              cache_write(last_modified_key, last_modified)
              cache_write(key, stored_obj)
            end
            
            ld_obj = stored_obj[:ld_obj]
          else
            ld_obj = LinkedData::Client::HTTP.object_from_json(requested_env[:body])
            expiry = requested_env[:response_headers]["Cache-Control"].to_s.split("=").last.to_i
            if expiry > 0 && last_modified
              # This request is cacheable, store it
              puts "STORING OBJECT: #{requested_env[:url].to_s}" if $DEBUG
              stored_obj = {last_modified: last_modified, ld_obj: ld_obj}
              cache_write(last_modified_key, last_modified)
              cache_write(last_retrieved_key, true, expires_in: expiry)
              cache_write(key, stored_obj)
            end
          end

          return ld_obj
        end
      end
    end
    
    private
    
    def cache_write(key, obj, *args)
      @store.write(key, obj, *args)
    end
    
    def cache_read(key)
      @store.read(key)
    end
    
    def cache_exist?(key)
      @store.exist?(key)
    end
    
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
    
    # Internal: Creates a new 'Hash' containing the request information.
    #
    # env - the environment 'Hash' from the Faraday stack.
    #
    # Returns a 'Hash' containing the ':method', ':url' and 'request_headers'
    # entries.
    def create_request(env)
      request = env.to_hash.slice(:method, :url, :request_headers)
      request[:request_headers] = request[:request_headers].dup
      request
    end
    
    def clean_request_headers(request)
      request[:request_headers].delete("If-Modified-Since")
      request[:request_headers].delete("Expect")
      request
    end
    
  end
end

if Faraday.respond_to?(:register_middleware)
  Faraday.register_middleware object_cache: Faraday::ObjectCache
elsif Faraday::Middleware.respond_to?(:register_middleware)
  Faraday::Middleware.register_middleware object_cache: Faraday::ObjectCache
end
