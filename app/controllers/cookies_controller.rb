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
      }
    else
      render json: {
        message: 'Cookies were rejected or has not been accepted.'
      }
    end
  end
end
