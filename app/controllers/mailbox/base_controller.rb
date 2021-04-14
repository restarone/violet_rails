class Mailbox::BaseController < Subdomains::Admin::BaseController
  before_action :check_email_authorization

  def check_email_authorization

  end
end