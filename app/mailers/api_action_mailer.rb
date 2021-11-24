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
        subject: "#{api_action.type} #{@api_resource.api_namespace.name.pluralize} v#{@api_resource.api_namespace.version}"
      )
    end
end
  