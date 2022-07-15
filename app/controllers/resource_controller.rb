class ResourceController < ApplicationController
  before_action :load_api_namespace
  
  include ApiActionable

  def create
    @api_resource = @api_namespace.api_resources.new(resource_params)
    if @api_namespace&.api_form&.show_recaptcha
      if verify_recaptcha(model: @api_resource) && @api_resource.save
        load_api_actions_from_api_resource
        handle_redirection
      else
        execute_error_actions
        flash[:error] = @api_resource.errors.full_messages.to_sentence
        redirect_back(fallback_location: root_path)
      end
    elsif @api_namespace&.api_form&.show_recaptcha_v3
      if verify_recaptcha(model: @api_resource, action: helpers.sanitize_recaptcha_action_name(@api_namespace.name), minimum_score: ApiForm::RECAPTCHA_V3_MINIMUM_SCORE, secret_key: ENV['RECAPTCHA_SECRET_KEY_V3']) && @api_resource.save
        load_api_actions_from_api_resource
        handle_redirection
      else
        execute_error_actions
        flash[:error] = @api_resource.errors.full_messages.to_sentence
        redirect_back(fallback_location: root_path)
      end
    elsif @api_resource.save
      load_api_actions_from_api_resource
      handle_redirection
    else
      execute_error_actions
      # show custom snippet only if failure_message contains valid html tags
      notice_type = @api_namespace.api_form&.failure_message_has_html? ? :custom_notice : :error
      flash[notice_type] = @api_namespace.api_form&.failure_message_evaluated
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
    params.require(:data).permit(properties: {}, non_primitive_properties_attributes: [:id, :label, :field_type, :content, :attachment, :allow_attachments, :_destroy])
  end
end