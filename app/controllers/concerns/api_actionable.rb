module ApiActionable
  extend ActiveSupport::Concern
  included do
    before_action :set_current_user_and_visit
    before_action :initialize_api_actions, only: [:update, :show, :destroy]
    before_action :check_for_custom_actions, only: [:create, :update, :show, :destroy]
    before_action :check_for_redirect_action, only: [:create, :update, :show, :destroy]
    before_action :check_for_serve_file_action, only: [:show, :create, :update, :destroy]
    rescue_from StandardError, with: :handle_error
  end

  def check_for_custom_actions
    @custom_actions = if @api_resource.present?
                        @api_resource.send(api_action_name).where(action_type: 'custom_action', lifecycle_stage: 'initialized')
                      else
                        @api_namespace.send(api_action_name).where(action_type: 'custom_action')
                      end
  end

  def check_for_redirect_action
    @redirect_action = if @api_resource.present?
                          @api_resource.send(api_action_name).where(action_type: 'redirect').reorder(:created_at).last
                        else
                          @api_namespace.send(api_action_name).where(action_type: 'redirect').last
                        end
  end

  def check_for_serve_file_action
    @serve_file_action = if @api_resource.present?
                            @api_resource.send(api_action_name).where(action_type: 'serve_file').reorder(:created_at).last
                          else
                            @api_namespace.send(api_action_name).where(action_type: 'serve_file').last
                          end
  end

  def handle_serve_file_action
    return if @serve_file_action.nil?

    @serve_file_action.update(lifecycle_stage: 'executing')
    file_id = helpers.file_id_from_snippet(@serve_file_action.file_snippet)
    file = Comfy::Cms::File.find(file_id)
    if params[:action] == 'show' && @redirect_action.nil?
      flash.now[:file_url] = rails_blob_url(file.attachment)
    else
      flash[:file_url] = rails_blob_url(file.attachment)
    end

    @serve_file_action.update(lifecycle_stage: 'complete', lifecycle_message: "label: #{file.label} id: #{file.id} mime_type: #{file.attachment.content_type}")
  end

  def handle_custom_actions
    flash[:notice] = @api_namespace.api_form.success_message
    if @custom_actions.present?
      @custom_actions.each do |custom_action|
        begin
          custom_api_action = CustomApiAction.new
          eval("def custom_api_action.run_custom_action(api_action: , api_namespace: , api_resource: , current_visit: , current_user: nil); #{custom_action.method_definition}; end")

          custom_action.update(lifecycle_stage: 'executing')

          response = custom_api_action.run_custom_action(api_action: custom_action, api_namespace: @api_namespace, api_resource: @api_resource, current_visit: current_visit, current_user: current_user)

          custom_action.update(lifecycle_stage: 'complete', lifecycle_message: response.to_json)
        rescue => e
          custom_action.update(lifecycle_stage: 'failed', lifecycle_message: e.message)
          execute_error_actions

          raise
        end
      end
    end
  end

  def handle_redirection
    flash[:notice] = @api_namespace.api_form.success_message || 'Api resource was successfully updated.'

    if @redirect_action.present?
      redirect_url = @redirect_action.dynamic_url? ? @redirect_action.redirect_url_evaluated : @redirect_action.redirect_url
      if @redirect_action.update!(lifecycle_stage: 'complete', lifecycle_message: redirect_url)
        redirect_to redirect_url and return
      else
        @redirect_action.update!(lifecycle_stage: 'failed', lifecycle_message: redirect_url)
        execute_error_actions
      end
    end

    redirect_back(fallback_location: root_path)
  end

  def execute_api_actions
    api_actions = @api_resource.send(api_action_name)

    ApiAction::EXECUTION_ORDER.each do |action_type|
      if ApiAction.action_types[action_type] == ApiAction.action_types[:serve_file]
        handle_serve_file_action if @serve_file_action.present?
      elsif ApiAction.action_types[action_type] == ApiAction.action_types[:redirect]
        handle_redirection
      elsif ApiAction.action_types[action_type] == ApiAction.action_types[:custom_action]
        handle_custom_actions if @custom_actions.present?
      elsif [ApiAction.action_types[:send_email], ApiAction.action_types[:send_web_request]].include?(ApiAction.action_types[action_type])
        api_actions.where(action_type: ApiAction.action_types[action_type]).each do |api_action|
          api_action.execute_action
        end
      end
    end if api_actions.present?
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

  def set_current_user_and_visit
    Current.user = current_user
    Current.visit = current_visit
  end

  def load_api_actions_from_api_resource
    @custom_actions = @api_resource.send(api_action_name).where(action_type: 'custom_action', lifecycle_stage: 'initialized') if @custom_actions.present?
    @redirect_action = @api_resource.send(api_action_name).where(action_type: 'redirect').reorder(:created_at).last if @redirect_action.present?
    @serve_file_action = @api_resource.send(api_action_name).where(action_type: 'serve_file').reorder(:created_at).last if @serve_file_action.present?
  end
end