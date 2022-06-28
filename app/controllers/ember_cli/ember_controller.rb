module EmberCli
  class EmberController < ::ApplicationController
    before_action :redirect_if_unsupported
    unless ancestors.include? ActionController::Base
      (
        ActionController::Base::MODULES -
        ActionController::API::MODULES
      ).each do |controller_module|
        include controller_module
      end

      helper EmberRailsHelper
    end

    def index
      render layout: false
    end

    private 

    def redirect_if_unsupported
      if !Subdomain.current.ember_enabled
        redirect_to root_path
      end
    end
  end
end
