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
      #  @meta_data["non_primitive_properties"] = [NonPrimitiveProperty.find_by(id: ApiAction.find(173).meta_data["api_resource"]["api_namespace_id"])]
      #  @meta_data["non_primitive_properties"] = [NonPrimitiveProperty.find_by(id: ApiAction.find(173).meta_data["api_resource"]["api_namespace_id"])]
        # @display_data = {
        #   "api_namespace": {
        #     "name": ApiNamespace.find_by(id: ApiAction.find(api_action.id).meta_data["api_resource"]["api_namespace_id"]),
        #     "properties":  @api_action.meta_data["api_resource"]["properties"]
        #   },
        #   "properties":  @api_action.meta_data["api_resource"]["properties"]
        # }
        # @display_data =  { :api_namespace => {:name => ApiNamespace.find_by(id: ApiAction.find(api_action.id).meta_data["api_resource"]["api_namespace_id"]) }}
        # @display_data[:api_namespace][:properties] = @api_action.meta_data["api_resource"]["properties"]
        # @display_data["properties"] = @api_action.meta_data["api_resource"]["properties"]
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
  