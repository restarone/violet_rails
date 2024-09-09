if NextRails.next?
  # Do things "the Rails 7 way"
  Rails.application.config.to_prepare do
    Geocoder.configure(
      # IP address geocoding service (default :ipinfo_io)
      ip_lookup: :ipapi_com,
      # https://github.com/alexreisner/geocoder#caching
      cache: Redis.new
    )
  end

else
  # Do things "the Rails 6 way"
  Geocoder.configure(
    # IP address geocoding service (default :ipinfo_io)
    ip_lookup: :ipapi_com,
    # https://github.com/alexreisner/geocoder#caching
    cache: Redis.new
  )
end
