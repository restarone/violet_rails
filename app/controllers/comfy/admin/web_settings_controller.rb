class Comfy::Admin::WebSettingsController < Comfy::Admin::Cms::BaseController
  layout "comfy/admin/cms"
  before_action :ensure_authority_to_manage_web_settings

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
      :favicon,
      :description,
      :keywords,
      :og_image,
      :blog_enabled,
      :forum_enabled,
      :allow_user_self_signup,
      :forum_is_private,
      :purge_visits_every,
      :analytics_report_frequency,
      :tracking_enabled,
      :cookies_consent_ui,
      :ember_enabled,
      :graphql_enabled,
      :web_console_enabled,
      :api_plugin_events_enabled,
      :after_sign_in_path,
      :after_sign_up_path,
      :allow_external_analytics_query,
      :email_name,
      :email_signature,
      :enable_2fa,
      :email_notification_strategy
    )
  end
end