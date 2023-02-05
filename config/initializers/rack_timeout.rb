#setting service_timeout from environment variable, RACK_TIMEOUT_SERVICE_TIMEOUT
Rails.application.config.middleware.insert_before Rack::Runtime, Rack::Timeout
