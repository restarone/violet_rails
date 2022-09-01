class CookiesController < ApplicationController
  def index
    cookies[:cookies_accepted] = params[:cookies].presence

    redirect_back fallback_location: root_path
  end
end
