class Subdomains::BaseController < ApplicationController
  before_action do 
    unless current_user || current_customer
      authenticate_customer!
    end
  end
  
  layout "subdomains"
end