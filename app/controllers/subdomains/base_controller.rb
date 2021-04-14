class Subdomains::BaseController < ApplicationController
  before_action :authenticate_user!
  layout "subdomains"
end