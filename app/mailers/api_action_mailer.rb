class ApiActionMailer < ApplicationMailer
    helper ApiResourcesHelper
    def send_email(api_action)
      mail_to = api_action.email_evaluated
      from = "#{Subdomain.current.name}@#{ENV["APP_HOST"]}"
      return if mail_to.empty?
    
      @api_action = api_action
      @api_resource = api_action.api_resource
      custom_subject = api_action.email_subject_evaluated || if api_action.api_namespace_action then  "#{api_action.type} #{api_action.api_namespace_action.api_namespace&.name.pluralize} v#{api_action.api_namespace_action.api_namespace&.version}" 
      else "#{api_action.type} #{@api_resource.api_namespace.name.pluralize} v#{@api_resource.api_namespace.version}" end
      
        mail(
        from: from,
        to: mail_to,
        subject: custom_subject
      )
    end
end
  