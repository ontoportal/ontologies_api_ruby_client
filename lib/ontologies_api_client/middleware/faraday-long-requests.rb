module Faraday
  class LongRequests < Faraday::Middleware
    def initialize(app, *arguments)
      super(app)
    end

    def call(env)
      dup.call!(env)
    end

    def call!(env)
      start = Time.now
      data = @app.call(env)
      finish = Time.now
      if finish - start > 2
        Thread.new do
          open("/Users/palexand/tmp/slow_requests.log", "a") do |f|
            f.puts "#{finish - start} #{env[:method].to_s.upcase} #{env[:url].to_s}"
          end
        end
      end
      data
    end
  end
end

if Faraday.respond_to?(:register_middleware)
  Faraday.register_middleware long_requests: Faraday::LongRequests
elsif Faraday::Middleware.respond_to?(:register_middleware)
  Faraday::Middleware.register_middleware long_requests: Faraday::LongRequests
end