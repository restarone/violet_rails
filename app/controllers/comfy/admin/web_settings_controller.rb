class Comfy::Admin::WebSettingsController < Comfy::Admin::Cms::BaseController
  layout "comfy/admin/cms"
  before_action :ensure_authority_to_manage_web

  def edit
    params[:q] ||= {}
    @visits_q = Subdomain.current.ahoy_visits.ransack(params[:q])
    @visits = @visits_q.result.paginate(page: params[:page], per_page: 10)
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
      :og_image  
    )
  end
end