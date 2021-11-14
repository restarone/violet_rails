module ApiActionable
  extend ActiveSupport::Concern
  included do
    before_action :initialize_api_actions, only: [:update, :show, :destroy]
    before_action :check_for_redirect_action, only: [:create, :update, :show, :destroy]
    after_action :execute_api_actions, only: [:show, :create, :update, :destroy]
    before_action :check_for_serve_file_action, only: [:show, :create, :update, :destroy]
    rescue_from StandardError, with: :handle_error
  end


  def check_for_redirect_action
    @redirect_action = @api_namespace.send("#{params[:action]}_api_actions".to_sym).where(action_type: 'redirect').last
  end

  def check_for_serve_file_action
    serve_file_action = @api_namespace.send("#{params[:action]}_api_actions".to_sym).where(action_type: 'serve_file').last
    return if serve_file_action.nil?

    serve_file_action.update(lifecycle_stage: 'executing')
    file_id = helpers.file_id_from_snippet(serve_file_action.file_snippet)
    file = Comfy::Cms::File.find(file_id)
    if params[:action] == 'show' && @redirect_action.nil?
      flash.now[:file_url] = rails_blob_url(file.attachment)
    else
      flash[:file_url] = rails_blob_url(file.attachment)
    end
    serve_file_action.update(lifecycle_stage: 'complete', lifecycle_message: file.label)
  end

  def handle_redirection
    flash[:notice] = @api_namespace.api_form.success_message
    if @redirect_action.present?
      @redirect_action.update!(lifecycle_stage: 'complete', lifecycle_message: @redirect_action.redirect_url.to_s)
      
      redirect_to @redirect_action.redirect_url and return 
    end

    redirect_back(fallback_location: root_path, notice: "Api resource was successfully updated.")
  end

  def execute_api_actions
    helpers.execute_actions(@api_resource, "#{params[:action]}_api_actions".to_sym)
  end

  def handle_error(e)
    execute_error_actions
    raise
  end

  def execute_error_actions
    error_api_actions = @api_resource.error_api_actions

    redirect_action = error_api_actions.where(action_type: 'redirect').last
    error_api_actions.each do |action|
      action.execute_action unless action.redirect?
    end

    if redirect_action
      redirect_action.update(lifecycle_stage: 'complete', lifecycle_message: redirect_action.redirect_url)
      redirect_to redirect_action.redirect_url and return 
    end
  end

  def initialize_api_actions
    @api_namespace.send("#{params[:action]}_api_actions".to_sym).each do |action|
      @api_resource.send("#{params[:action]}_api_actions".to_sym).create(action.attributes.except("id", "created_at", "updated_at", "api_namespace_id"))
    end
  end
end