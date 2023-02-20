class Rack::Attack
  # Allows 120 requests/IP in ~1 minutes
  #        240 requests/IP in ~8 minutes
  #        480 requests/IP in ~1 hour
  #        960 requests/IP in ~8 hours (~2,880 requests/day)
  (2..5).each do |level|
    throttle("req/ip/#{level}",
               :limit => (30 * (2 ** level)),
               :period => (0.9 * (8 ** level)).to_i.seconds) do |req|
      req.ip unless req.env['warden'].user&.global_admin || req.path.start_with?('/rails/active_storage')
    end
  end
end

