class ApiActionMailer < ApplicationMailer
    helper ApiResourcesHelper
    def send_email(api_action)
      mail_to = api_action.email_evaluated
      from = "#{Subdomain.current.name}@#{ENV["APP_HOST"]}"
      return if mail_to.empty?
      @api_action = api_action
      @api_resource = api_action.api_resource
      
      if !@api_resource && api_action.meta_data
       @meta_data =  api_action.meta_data["api_resource"]
       @meta_data["namespace"] = ApiNamespace.find_by(id: ApiAction.find(api_action.id).meta_data["api_resource"]["api_namespace_id"])
      end
      
      custom_subject = api_action.email_subject_evaluated || if api_action.api_namespace_action then  "#{api_action.type} #{api_action.api_namespace_action.api_namespace&.name.pluralize} v#{api_action.api_namespace_action.api_namespace&.version}" 
      else "#{api_action.type} #{@api_resource.api_namespace.name.pluralize} v#{@api_resource.api_namespace.version}" end
      
      mail(
        from: from,
        to: mail_to,
        subject: custom_subject
      )
    end
end
  