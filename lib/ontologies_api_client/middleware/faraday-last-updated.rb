module Faraday
  ##
  # This middleware causes Faraday to return
  class LastUpdated < Faraday::Middleware
    def initialize(app, *arguments)
      super(app)
    end

    def call(env)
      session = Thread.current[:session]
      if session && session[:last_updated]
        headers = env[:request_headers]
        headers["NCBO-Cache"] = session[:last_updated]
        env[:request_headers] = headers
      end
      @app.call(env)
    end

  end
end

if Faraday.respond_to?(:register_middleware)
  Faraday.register_middleware last_updated: Faraday::LastUpdated
elsif Faraday::Middleware.respond_to?(:register_middleware)
  Faraday::Middleware.register_middleware last_updated: Faraday::LastUpdated
end