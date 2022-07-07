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
    @redirect_action = if @api_resource.present?
                        @api_resource.send(api_action_name).where(action_type: 'redirect', lifecycle_stage: 'initialized').last
                      else
                        @api_namespace.send(api_action_name).where(action_type: 'redirect').last
                      end
  end

  def check_for_serve_file_action
    serve_file_action = @api_namespace.send(api_action_name).where(action_type: 'serve_file').last
    serve_file_action = if @api_resource.present?
                        @api_resource.send(api_action_name).where(action_type: 'serve_file', lifecycle_stage: 'initialized').last
                      else
                        @api_namespace.send(api_action_name).where(action_type: 'serve_file').last
                      end
    return if serve_file_action.nil?

    serve_file_action.update(lifecycle_stage: 'executing')
    file_id = helpers.file_id_from_snippet(serve_file_action.file_snippet)
    file = Comfy::Cms::File.find(file_id)
    if params[:action] == 'show' && @redirect_action.nil?
      flash.now[:file_url] = rails_blob_url(file.attachment)
    else
      flash[:file_url] = rails_blob_url(file.attachment)
    end
    serve_file_action.update(lifecycle_stage: 'complete', lifecycle_message: "label: #{file.label} id: #{file.id} mime_type: #{file.attachment.content_type}")
  end

  def handle_redirection
    flash[:notice] = @api_namespace.api_form.success_message
    if @redirect_action.present?
      if @redirect_action.update!(lifecycle_stage: 'complete', lifecycle_message: @redirect_action.redirect_url.to_s)
        redirect_to evaluate_redirect_url and return
      else
        @redirect_action.update!(lifecycle_stage: 'failed', lifecycle_message: @redirect_action.redirect_url.to_s)
        execute_error_actions
      end
    end

    redirect_back(fallback_location: root_path, notice: "Api resource was successfully updated.")
  end

  def execute_api_actions
    helpers.execute_actions(@api_resource, api_action_name)
  end

  def handle_error(e)
    clone_actions(:error_api_actions)
    execute_error_actions
    raise
  end

  def execute_error_actions
    return if @api_resource.nil?

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
    clone_actions(api_action_name)
  end

  def api_action_name
    return "#{params[:action]}_api_actions".to_sym if ['new', 'update', 'show', 'create', 'destroy'].include?(params[:action])
  end

  # create api_actions for api_resource using api_namespace's api_actions as template
  def clone_actions(action_name)
    return if @api_resource.nil?

    @api_namespace.send(action_name).each do |action|
      @api_resource.send(action_name).create(action.attributes.merge(custom_message: action.custom_message.to_s).except("id", "created_at", "updated_at", "api_namespace_id"))
    end
  end

  def load_api_actions_from_api_resource
    @redirect_action = @api_resource.send(api_action_name).where(action_type: 'redirect').reorder(:created_at).last if @redirect_action.present?
    @serve_file_action = @api_resource.send(api_action_name).where(action_type: 'serve_file').reorder(:created_at).last if @serve_file_action.present?
  end

  def evaluate_redirect_url
    if @redirect_action.dynamic_url?
      redirect_url = @redirect_action.redirect_url.gsub('api_resource', '@redirect_action.api_resource')
      dynamic_url = redirect_url

      # couldn't gsub directly because of escape characters added by ruby
      # eval failed on "\#{api_resource.properties[\"String\"]}"
      redirect_url.scan(/\#\{(.*?)\}/).each do |code|
        dynamic_url = dynamic_url.sub!("\#{#{code[0]}}", eval(code[0]).to_s)
      end

      dynamic_url.html_safe
    else
      @redirect_action.redirect_url
    end
  end
end