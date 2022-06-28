Rails.application.reloader.to_prepare do
  class Ahoy::Store < Ahoy::DatabaseStore
  end

  # set to true for JavaScript tracking
  Ahoy.api = false

  # set to true for geocoding
  # we recommend configuring local geocoding first
  # see https://github.com/ankane/ahoy#geocoding
  Ahoy.geocode = true
  Ahoy.job_queue = :default
end
