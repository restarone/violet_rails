class CookiesController < ApplicationController
  def index
    cookies[:cookies_accepted] = params[:cookies].presence
    set_ahoy_cookies if params[:cookies].presence
  end
end
