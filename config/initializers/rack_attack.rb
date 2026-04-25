Rack::Attack.throttle("requests by ip", limit: 20, period: 2) do |request|
  request.ip
end

Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" }) 
