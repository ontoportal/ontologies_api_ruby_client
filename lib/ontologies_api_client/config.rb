require 'ostruct'
require 'faraday'
require 'faraday/multipart'
require 'excon'
require 'logger'

module LinkedData
  module Client
    extend self
    attr_reader :settings

    @settings = OpenStruct.new
    @settings_run = false
    @settings_run_connection = false

    def config(&block)
      return if @settings_run
      @settings_run = true

      yield @settings if block_given?

      # Set defaults
      @settings.rest_url                ||= "http://stagedata.bioontology.org"
      @settings.apikey                  ||= "4ea81d74-8960-4525-810b-fa1baab576ff"
      @settings.links_attr              ||= "links"
      @settings.cache                   ||= false
      @settings.enable_long_request_log ||= false
      @settings.purl_prefix             ||= "http://purl.example.org"

      # Remove trailing slash
      @settings.rest_url    = @settings.rest_url.chomp("/")
      @settings.purl_prefix = @settings.purl_prefix.chomp("/")

      @settings_run = true
    end

    def config_connection(options = {})
      return if @settings_run_connection
      store = options[:cache_store]
      @settings.conn = Faraday.new(@settings.rest_url) do |faraday|
        if @settings.enable_long_request_log
          require_relative 'middleware/faraday-long-requests'
          faraday.use :long_requests
        end

        require_relative 'middleware/faraday-user-apikey'
        faraday.use :user_apikey

        require_relative 'middleware/faraday-slices'
        faraday.use :ncbo_slices

        require_relative 'middleware/faraday-last-updated'
        faraday.use :last_updated

        if @settings.cache
          begin
            require_relative 'middleware/faraday-object-cache'
            faraday.use :object_cache, store: store
            puts "=> faraday caching enabled"
            puts "=> faraday cache store: #{store.class}"
          rescue LoadError
            puts "=> WARNING: faraday http cache gem is not available, caching disabled"
          end
        end

        faraday.request :multipart
        faraday.request :url_encoded
        faraday.adapter :excon
        faraday.headers = {
          "Accept" => "application/json",
          "Authorization" => "apikey token=#{@settings.apikey}",
          "User-Agent" => "NCBO API Ruby Client v0.1.0"
        }
      end
      @settings_run_connection = true
    end

    def connection_configured?
      @settings_run_connection
    end
  end
end