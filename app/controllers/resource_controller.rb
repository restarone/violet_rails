class ResourceController < ApplicationController
    before_action :load_api_namespace

    def create
      api_resource = @api_namespace.api_resources.new(resource_params)
      if @api_namespace&.api_form&.show_recaptcha
        if verify_recaptcha(action: 'create') && api_resource.save
            flash[:notice] = @api_namespace.api_form.success_message
            redirect_back(fallback_location: root_path)
        else
          flash[:error] = api_resource.errors.full_messages.to_sentence
          redirect_back(fallback_location: root_path)
        end
      elsif api_resource.save
          flash[:notice] = @api_namespace.api_form.success_message
          redirect_back(fallback_location: root_path)
      else
          flash[:error] = @api_namespace.api_form.error_message
          redirect_back(fallback_location: root_path)
      end
    end
  
    private

    def load_api_namespace
      @api_namespace = ApiNamespace.find_by(id: params[:api_namespace_id])
    end
  
    def resource_params
      properties = params[:data].try(:permit!).except(:non_primitive_properties_attributes)
      params.require(:data).permit(non_primitive_properties_attributes: [:id, :label, :field_type, :content, :attachment, :_destroy]).merge({ api_namespace_id: params[:api_namespace_id], properties: properties })
    end
  end
  