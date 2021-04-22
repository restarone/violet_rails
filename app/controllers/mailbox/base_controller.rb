class Mailbox::BaseController < Comfy::Admin::Cms::BaseController
  before_action :check_email_authorization

  def check_email_authorization

  end
end