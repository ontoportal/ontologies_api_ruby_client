module Faraday
  ##
  # This middleware causes Faraday to return
  class Slices < Faraday::Middleware
    def initialize(app, *arguments)
      super(app)
    end

    def call(env)
      active_slice = Thread.current[:slice] && Thread.current[:slice][:active]
      if active_slice
        headers = env[:request_headers]
        headers["NCBO-Slice"] = Thread.current[:slice][:acronym]
        env[:request_headers] = headers
      end
      @app.call(env)
    end

  end
end

if Faraday.respond_to?(:register_middleware)
  Faraday.register_middleware ncbo_slices: Faraday::Slices
elsif Faraday::Middleware.respond_to?(:register_middleware)
  Faraday::Middleware.register_middleware ncbo_slices: Faraday::Slices
end