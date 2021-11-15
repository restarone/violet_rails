class ResourceController < ApplicationController
  before_action :load_api_namespace
  
  include ApiActionable

  def create
    @api_resource = @api_namespace.api_resources.new(resource_params)
    if @api_namespace&.api_form&.show_recaptcha
      if verify_recaptcha(action: 'create') && @api_resource.save
        handle_redirection
      else
        execute_error_actions
        flash[:error] = @api_resource.errors.full_messages.to_sentence
        redirect_back(fallback_location: root_path)
      end
    elsif @api_resource.save
      handle_redirection
    else
      execute_error_actions
      flash[:error] = @api_namespace.api_form.failure_message if @api_namespace.api_form.present?
      redirect_back(fallback_location: root_path)
    end
  end
  
  private

  def load_api_namespace
    @api_namespace = ApiNamespace.find_by(id: params[:api_namespace_id])
  end
  
  def resource_params
    # it comes in as a json string which we need to parse into a ruby hash before saving it to the DB 
    JSON.parse(@api_namespace.properties).each do |key, value|
      if value.class.to_s == 'Hash'
        params[:data][:properties][key] = JSON.parse params[:data][:properties][key]
      end
    end
    params.require(:data).permit(properties: {}, non_primitive_properties_attributes: [:id, :label, :field_type, :content, :attachment, :_destroy])
  end
end