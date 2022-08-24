class CookiesController < ApplicationController
  def index
    cookies[:cookies_accepted] = params[:cookies].presence
  end
end
