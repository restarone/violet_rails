class ApiActionMailer < ApplicationMailer
    helper ApiResourcesHelper
    def send_email(api_action)
      mail_to = api_action.email_evaluated
      from = "#{Subdomain.current.name}@#{ENV["APP_HOST"]}"
      return if mail_to.empty?
    
      @api_action = api_action
      @api_resource = api_action.api_resource
      mail(
        from: from,
        to: mail_to,
        subject: api_action.email_subject_evaluated || "#{api_action.type} #{@api_resource&.api_namespace.name.pluralize} v#{@api_resource&.api_namespace.version}"
      )
    end
end
  