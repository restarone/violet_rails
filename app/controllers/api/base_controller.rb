class Api::BaseController < ApplicationController
  before_action :authenticate_request
  def authenticate_request
    true
  end
end
