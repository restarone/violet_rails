Geocoder.configure(
  # IP address geocoding service (default :ipinfo_io)
  ip_lookup: :ipapi_com,
  # https://github.com/alexreisner/geocoder#caching
  cache: Redis.new
)