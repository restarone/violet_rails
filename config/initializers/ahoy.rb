class Ahoy::Store < Ahoy::DatabaseStore
  def track_visit(data)
    return unless tracking_enabled?

    super(data)
  end

  def track_event(data)
    return unless tracking_enabled?

    super(data)
  end

  def tracking_enabled?
    Subdomain.current.tracking_enabled && request.cookies['cookies_accepted'] == 'true'
  end
end

if NextRails.next?
  # Do things "the Rails 7 way"
  Rails.application.config.to_prepare do
    Ahoy::Controller.prepend(AhoyControllerPatch)
  end

else
  # Do things "the Rails 6 way"
  Ahoy::Controller.prepend(AhoyControllerPatch)
end

# set to true for JavaScript tracking
Ahoy.api = false

# set to true for geocoding
# we recommend configuring local geocoding first
# see https://github.com/ankane/ahoy#geocoding
Ahoy.geocode = true
Ahoy.job_queue = :default
