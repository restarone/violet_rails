if Rails.env.production?
  Sidekiq.configure_server { |c| c.redis = { url: ENV['REDIS_URL'] } }
else
  if Rails.env.development?
    Sidekiq.configure_server { |c| c.redis = { url: ENV['REDIS_URL'] } }
  else
    Sidekiq.configure_server { |c| c.redis = { url: ENV['REDIS_URL'] } }
  end
end