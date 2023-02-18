Rails.application.config.middleware.insert_before Rack::Runtime, Rack::Timeout

module MyRackTimeout
  module Timeout
    class CustomTimeoutMiddleware
      def initialize(app, service_timeout)
        @app = app
        @service_timeout = service_timeout
      end

      def call(env)
        thread = Thread.current
        timer_thread = Thread.new do
          sleep @service_timeout
          thread.safe_raise(timeout: 3, exception: "Request timed out")
        end

        status, headers, body = @app.call(env)
        [status, headers, body]
      ensure
        timer_thread.kill if timer_thread&.alive?
      end
    end
  end
end

Rails.application.config.middleware.insert_before Rack::Timeout, MyRackTimeout::Timeout::CustomTimeoutMiddleware, service_timeout: 0.5
# MyRackTimeout::Timeout.service_timeout = 5 # Set a global service timeout of 5 seconds


# Rails.application.config.middleware.insert_before Rack::Runtime, Rack::Timeout

# module Rack
#   module Timeout
#     class CustomTimeoutMiddleware
#       def initialize(app)
#         @app = app
#       end

#       def call(env)
#         timer_thread = Thread.new do
#           sleep Rack::Timeout.timeout
#           env['rack.timeout_info'] = { error: 'Request timed out' }
#           env['rack.timeout_info'].merge!(timeout: Rack::Timeout.timeout)
#           env['rack.timeout_info'].merge!(state: 'completed')
#           env['rack.timeout_info'].merge!(exception: false)
#           Thread.current.raise RequestTimeoutException
#         end

#         begin
#           @app.call(env)
#         rescue RequestTimeoutException => e
#           env['rack.timeout_info'].merge!(exception: true)
#           env['rack.timeout_info'].merge!(state: 'timed_out')
#           [503, {}, ['Request timed out']]
#         ensure
#           timer_thread.kill if timer_thread&.alive?
#         end
#       end
#     end
#   end
# end

# Rails.application.config.middleware.insert_before Rack::Timeout, Rack::Timeout::CustomTimeoutMiddleware

# class RequestTimeoutException < StandardError; end

# Rails.application.config.middleware.insert_before Rack::Runtime, Rack::Timeout

# module Rack
#   module Timeout
#     class CustomTimeoutMiddleware
#       def initialize(app)
#         @app = app
#       end

#       def call(env)
#         thread = Thread.current
#         timer_thread = Thread.new do
#           sleep Rack::Timeout.timeout
#           thread.safe_raise(timeout: 3, exception: RequestTimeoutException.new('Request timed out'))
#         end

#         begin
#           @app.call(env)
#         rescue RequestTimeoutException => e
#           [503, {}, ['Request timed out']]
#         ensure
#           timer_thread.kill if timer_thread&.alive?
#         end
#       end
#     end
#   end
# end

# Rails.application.config.middleware.insert_before Rack::Timeout, Rack::Timeout::CustomTimeoutMiddleware

# class RequestTimeoutException < StandardError; end