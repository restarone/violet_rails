class CookiesController < ApplicationController
  def index
    cookies[:cookies_accepted] = {
      value: params[:cookies].presence,
      httponly: true,
      expires: 1.year
    }

    redirect_back fallback_location: root_path
  end

  def fetch
    if tracking_enabled?
      render json: {
        cookies_accepted: cookies[:cookies_accepted],
        ahoy_visitor_token: cookies[:ahoy_visitor],
        ahoy_visit_token: cookies[:ahoy_visit]
      }.merge(metadata: geolocation_data)
    else
      render json: {
        message: 'Cookies were rejected or has not been accepted.'
      }.merge(metadata: geolocation_data)
    end
  end

  private
  def geolocation_data
    {
      ip_address: request.remote_ip,
      country: request.safe_location.country.presence || 'not available',
      country_code: request.safe_location.country_code.presence || 'not available'
    }
  end
end
