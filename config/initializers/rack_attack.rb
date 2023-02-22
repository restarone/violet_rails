# Rack::Attack.cache.store = ActiveSupport::Cache::RedisStore.new(ENV[REDIS_URL])
class Rack::Attack
  MAX_THROTTLE_LEVEL = 5
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
  # Ban IP for 12 hours if all 5 levels are activated

  # https://github.com/rack/rack-attack/blob/main/docs/advanced_configuration.md#exponential-backoff
  (0..MAX_THROTTLE_LEVEL).each do |level|
    throttle("req/ip/#{level}",
               :limit => (REQUEST_LIMIT * (level + 1)),
               :period => (MULTIPLIER ** level)*60) do |req|
      req.ip unless (req.env['warden'].user&.global_admin || req.path.start_with?('/rails/active_storage'))
    end
  end
  
  Rack::Attack.blocklist("ban/ip}".to_sym) do |req|
    Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 0, findtime: (MULTIPLIER ** (MAX_THROTTLE_LEVEL + 1))*60, bantime: 12.hours) do
      !req.env['warden'].user&.global_admin && !req.path.start_with?('/rails/active_storage') && configuration.throttles["req/ip/#{MAX_THROTTLE_LEVEL}"].exceeded?(req)
    end
  end
  # (0..5).each do |level|
  #   ban_limit = (ERROR_LIMIT * (level + 1))
  #   ban_period = (MULTIPLIER ** level)*60
  #   Rack::Attack.blocklist("error_request/ip/#{level}".to_sym) do |req|
  #     Rack::Attack::Allow2Ban.filter(req.ip, maxretry: ban_limit, findtime: ban_period, bantime: ban_period) do
  #       req.env["rack.exception"].present? && !req.env['warden'].user&.global_admin && !req.path.start_with?('/rails/active_storage')
  #     end
  #   end
  # end
end

# ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |name, start, finish, request_id, payload|
  
# end

ActiveSupport::Notifications.subscribe("blocklist.rack_attack") do |name, start, finish, request_id, payload|
  user = payload[:request].env['warden'].user
  RackAttackMailer.limit_exceeded(user).deliver_later if user.present?
end

class Rack::Attack::Throttle 
  def exceeded?(request)
    discriminator = discriminator_for(request)
    return false unless discriminator
  
    current_period = period_for(request)
    current_limit = limit_for(request)
  
    key = [Time.now.to_i / current_period, name, discriminator].join(':')
    count = cache.read(key).to_i
  
    count >= current_limit
  end
end