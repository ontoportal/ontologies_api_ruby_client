require 'ostruct'
require 'faraday'
require 'typhoeus'
require 'logger'

module LinkedData
  module Client
    extend self
    attr_reader :settings

    @settings = OpenStruct.new
    @settings_run = false

    def config(&block)
      return if @settings_run
      @settings_run = true

      yield @settings if block_given?

      # Set defaults
      @settings.rest_url   ||= "http://stagedata.bioontology.org/"
      @settings.apikey     ||= "4ea81d74-8960-4525-810b-fa1baab576ff"
      @settings.links_attr ||= "links"
      @settings.cache      ||= false
      
      @settings.conn = Faraday.new(@settings.rest_url) do |faraday|
        if @settings.cache
          begin
            require_relative 'middleware/faraday-object-cache'
            faraday.use :object_cache
            require 'faraday-http-cache'
            faraday.use :http_cache, logger: Rails.logger, serializer: Marshal
            puts "=> faraday caching enabled"
          rescue LoadError
            puts "=> WARNING: faraday http cache gem is not available, caching disabled"
          end
        end
        faraday.request :url_encoded
        faraday.request :multipart
        faraday.adapter :typhoeus
        faraday.headers = {
          "Accept" => "application/json",
          "Authorization" => "apikey token=#{@settings.apikey}",
          "User-Agent" => "NCBO API Ruby Client v0.1.0"
        }
      end
      
      @settings_run = true
    end
  end
end