class Comfy::Admin::WebSettingsController < Comfy::Admin::Cms::BaseController
  layout "comfy/admin/cms"
  before_action :ensure_authority_to_manage_web

  def edit
  end

  def update
    if Subdomain.current.update(subdomain_params)
      flash.notice = 'Settings updated'
    else
      flash.alert = 'Settings could not be updated please try again'
    end
    redirect_to edit_web_settings_path
  end

  private

  def subdomain_params
    params.require(:subdomain).permit(
      :html_title,
      :blog_title,
      :blog_html_title,
      :forum_title,
      :forum_html_title,
      :logo,
      :favicon
    )
  end

  def ensure_authority_to_manage_web
    unless current_user.can_manage_web
      flash.alert = "You do not have the permission to do that. Only users who can_manage_web are allowed to perform that action."
      redirect_back(fallback_location: root_url)
    end
  end
end