class Admin::WebConsoleController < Admin::BaseController
  before_action :redirect_if_unsupported
  def index
  end

  private

  def redirect_if_unsupported
    if !Subdomain.current.web_console_enabled
      redirect_to root_path
    end
  end
end
