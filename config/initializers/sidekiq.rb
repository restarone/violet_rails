Sidekiq.configure_server { |c| c.redis = { url: ENV['REDIS_URL'] } }
Sidekiq.strict_args!
