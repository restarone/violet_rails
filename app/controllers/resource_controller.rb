class ResourceController < ApplicationController
  before_action :load_api_namespace

  include ApiActionable

  def create
    @api_resource = @api_namespace.api_resources.new(resource_params)
    if @api_namespace&.api_form&.show_recaptcha || session[:recaptcha_v2_fallback]
      session.delete(:recaptcha_v2_fallback) if session[:recaptcha_v2_fallback]
      if verify_recaptcha(model: @api_resource) && @api_resource.save
        load_api_actions_from_api_resource
        execute_api_actions
      else
        execute_error_actions
        render_error(@api_resource.errors.full_messages.to_sentence)
      end
    elsif @api_namespace&.api_form&.show_recaptcha_v3
      if verify_recaptcha(model: @api_resource, action: helpers.sanitize_recaptcha_action_name(@api_namespace.name), minimum_score: ApiForm::RECAPTCHA_V3_MINIMUM_SCORE, secret_key: ENV['RECAPTCHA_SECRET_KEY_V3']) && @api_resource.save
        load_api_actions_from_api_resource
        execute_api_actions
      else
        session[:recaptcha_v2_fallback] = true if recaptcha_reply && recaptcha_reply['score'].to_f < ApiForm::RECAPTCHA_V3_MINIMUM_SCORE
        execute_error_actions
        render_fallback_to_recaptcha_v2_with_error_message(@api_resource.errors.full_messages.to_sentence)
      end
    elsif @api_resource.save
      load_api_actions_from_api_resource
      execute_api_actions
    else
      execute_error_actions
      render_error(@api_namespace.api_form&.failure_message)
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