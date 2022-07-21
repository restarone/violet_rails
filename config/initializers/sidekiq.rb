Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'], namespace: "#{ENV['APP_HOST']}_#{Rails.env}" }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'], namespace: "#{ENV['APP_HOST']}_#{Rails.env}" }
end   

Sidekiq.strict_args!