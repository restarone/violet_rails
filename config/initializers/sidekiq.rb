if Rails.env.production?
  Sidekiq.configure_server { |c| c.redis = { url: ENV['REDIS_URL'] } }
else
  if Rails.env.development?
    Sidekiq.configure_server { |c| c.redis = { url: 'redis://solutions_redis:6379/12' } }
  else
    Sidekiq.configure_server { |c| c.redis = { url: 'redis://localhost:6379' } }
  end
end