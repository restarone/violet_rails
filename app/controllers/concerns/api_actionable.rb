module ApiActionable
  extend ActiveSupport::Concern
  included do
    before_action :check_for_redirect_action, only: [:update, :show, :destroy]
    after_action :execute_api_actions, only: [:show, :create, :update, :destroy]
    before_action :check_for_serve_file_action, only: [:show, :create, :update, :destroy]
  end

  def check_for_redirect_action
    @redirect_action = @api_namespace.send("#{params[:action]}_api_actions".to_sym).where(action_type: 'redirect').last
  end

  def check_for_serve_file_action
    serve_file_action = @api_namespace.send("#{params[:action]}_api_actions".to_sym).where(action_type: 'serve_file').last
    return if serve_file_action.nil?

    file_id = ComfortableMexicanSofa::Content::Renderer.new(:page).tokenize(serve_file_action.file_snippet).last[:tag_params]
    if params[:action] == 'show' && @redirect_action.nil?
      flash.now[:file_url] = rails_blob_url(Comfy::Cms::File.find(file_id).attachment)
    else
      flash[:file_url] = rails_blob_url(Comfy::Cms::File.find(file_id).attachment)
    end
  end

  def handle_redirection
    flash[:notice] = @api_namespace.api_form.success_message
    redirect_to @redirect_action.redirect_url and return if @redirect_action.present?

    redirect_to api_namespace_resource_path(api_namespace_id: @api_resource.api_namespace_id, id: @api_resource.id), notice: "Api resource was successfully updated."
  end

  def execute_api_actions
    execute_actions(@api_resource, "#{params[:action]}_api_actions".to_sym)
  end
end