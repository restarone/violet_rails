# Rack::Attack.cache.store = ActiveSupport::Cache::RedisStore.new(ENV[REDIS_URL])
class Rack::Attack
  REQUEST_LIMIT = ENV['REQUEST_PER_MINUTE'].to_i.nonzero? || 100
  ERROR_LIMIT = ENV['ERROR_PER_MINUTE'].to_i.nonzero? || 30
  MULTIPLIER = ENV['PERIOD_MULTIPLIER'].to_i.nonzero? || 2
  
  # When REQUEST_PER_MINUTE = 100
  #      PERIOD_MULTIPLIER = 2
  # Allows 100 requests/IP in 1 minute   - 100 requests in first 1 minute 
  #        200 requests/IP in 2 minutes  - 100 requests in next 1 minute
  #        300 requests/IP in 4 minutes  - 100 requests in next 2 minutes
  #        400 requests/IP in 8 minutes  - 100 requests in next 4 minutes
  #        500 requests/IP in 16 minutes - 100 requests in next 8 minutes
  #        600 requests/IP in 32 minutes - 100 requests in next 16 minutes
  #
  # Ban IP for 12 hours if all 6 levels are activated

  (0..5).each do |level|
    throttle("req/ip/#{level}",
               :limit => (REQUEST_LIMIT * (level.nonzero? || 1)),
               :period => (MULTIPLIER ** level).minutes) do |req|
      return if (req.env['warden'].user&.global_admin || req.path.start_with?('/rails/active_storage'))
      req.ip
    end
  end
  
  (0..5).each do |level|
    ban_limit = (ERROR_LIMIT * (level.nonzero? || 1))
    ban_period = (MULTIPLIER ** level).minutes
    Rack::Attack.blocklist("error_request/ip/#{level}".to_sym) do |req|
      Rack::Attack::Allow2Ban.filter(req.ip, maxretry: ban_limit, findtime: ban_period, bantime: ban_period) do
        req.env["rack.exception"].present? && !req.env['warden'].user&.global_admin && !req.path.start_with?('/rails/active_storage')
      end
    end
  end

  Rack::Attack.blocklist("ban/ip}".to_sym) do |req|
    Rack::Attack::Allow2Ban.filter(req.ip, maxretry: REQUEST_LIMIT * 6, findtime: 32.minutes, bantime: 12.hours) do
      !req.env['warden'].user&.global_admin && !req.path.start_with?('/rails/active_storage')
    end
  end
end

ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |name, start, finish, request_id, payload|

end

