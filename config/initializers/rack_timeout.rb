Rails.application.config.middleware.insert_before Rack::Runtime, Rack::Timeout

module MyRackTimeout
  module Timeout
    class CustomTimeoutMiddleware
      def initialize(app)
        @app = app
      end

      def call(env)
        if env['PATH_INFO']&.starts_with?('/ember-build')
          @app.call(env)
        else
          service_timeout = env['RACK_TIMEOUT_SERVICE_TIMEOUT'].to_f
          thread = Thread.current
          timer_thread = Thread.new do
            sleep service_timeout
            thread.safe_raise(timeout: 3, exception: "Request timed out")
          end

          status, headers, body = @app.call(env)
          [status, headers, body]
        end
      ensure
        timer_thread&.kill if timer_thread&.alive?
      end
    end
  end
end

Rails.application.config.middleware.insert_before Rack::Timeout, MyRackTimeout::Timeout::CustomTimeoutMiddleware