class Customers::BaseController < ApplicationController
  before_action :authenticate_customer!
  layout "customers"
end