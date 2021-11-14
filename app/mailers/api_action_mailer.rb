class ApiActionMailer < ApplicationMailer
    helper ApiResourcesHelper
    def send_email(api_action)
      mail_to = api_action.email
      return if mail_to.empty?
    
      @api_action = api_action
      @api_resource = api_action.api_resource

      p "sending api action mail for #{mail_to}"
      mail(
        to: mail_to,
        subject: "Api Action mail"
      )
    end
end
  