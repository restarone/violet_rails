class ApiActionMailer < ApplicationMailer
    helper ApiResourcesHelper
    def send_email(api_action)
      mail_to = api_action.email
      return if mail_to.empty?
    
      @api_action = api_action
      @api_resource = api_action.api_resource
      mail(
        to: mail_to,
        subject: api_action.email_subject_evaluated
      )
    end
end
  