class ResourceController < ApplicationController
  before_action :load_api_namespace, :check_for_redirect_action
  after_action :execute_api_actions

  def create
    @api_resource = @api_namespace.api_resources.new(resource_params)
    if @api_namespace&.api_form&.show_recaptcha
      if verify_recaptcha(action: 'create') && @api_resource.save
        handle_redirection
      else
        flash[:error] = @api_resource.errors.full_messages.to_sentence
        redirect_back(fallback_location: root_path)
      end
    elsif @api_resource.save
      handle_redirection
    else
      flash[:error] = @api_namespace.api_form.failure_message if @api_namespace.api_form.present?
      redirect_back(fallback_location: root_path)
    end
  end
  
  private

  def load_api_namespace
    @api_namespace = ApiNamespace.find_by(id: params[:api_namespace_id])
  end
  
  def resource_params
    params.require(:data).permit(properties: {}, non_primitive_properties_attributes: [:id, :label, :field_type, :content, :attachment, :_destroy])
  end

  def execute_api_actions
    api_actions = @api_resource.api_actions.where(trigger: "#{params[:action]}_event")
    api_actions.each do |api_action|
      if api_action.serve_file?
        flash[:file_url] = api_action.file_snippet
      else
        api_action.execute_action
      end
    end
  end

  def check_for_redirect_action
    @redirect_action = @api_namespace.api_actions.where(trigger: "#{params[:action]}_event", action_type: 'redirect').last
  end

  def handle_redirection
    flash[:notice] = @api_namespace.api_form.success_message
    redirect_to @redirect_action.redirect_url && return if @redirect_action.present?

    redirect_back(fallback_location: root_path)
  end
end