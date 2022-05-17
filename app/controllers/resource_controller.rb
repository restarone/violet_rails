class ResourceController < ApplicationController
  before_action :load_api_namespace

  include ApiActionable

  def create
    @api_resource = @api_namespace.api_resources.new(resource_params)
    if @api_namespace&.api_form&.show_recaptcha
      if verify_recaptcha(model: @api_resource) && @api_resource.save
        load_api_actions_from_api_resource
        execute_api_actions
      else
        execute_error_actions
        flash[:error] = @api_resource.errors.full_messages.to_sentence
        redirect_back(fallback_location: root_path)
      end
    elsif @api_resource.save
      load_api_actions_from_api_resource
      execute_api_actions
    else
      execute_error_actions
      flash[:error] = @api_namespace.api_form.failure_message if @api_namespace.api_form.present?
      redirect_back(fallback_location: root_path)
    end
  end

  private

  def load_api_namespace
    @api_namespace = ApiNamespace.find_by(id: params[:api_namespace_id])
    parse_incoming_resource_parameters
  end

  def parse_incoming_resource_parameters
    @api_namespace.properties.each do |key, value|
      if value.class.to_s == 'Hash'
        params[:data][:properties][key] = JSON.parse params[:data][:properties][key]
      end
    end
  end

  def resource_params
    params.require(:data).permit(properties: {}, non_primitive_properties_attributes: [:id, :label, :field_type, :content, :attachment, :_destroy])
  end
end