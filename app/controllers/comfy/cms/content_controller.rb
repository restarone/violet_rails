# frozen_string_literal: true

class Comfy::Cms::ContentController < Comfy::Cms::BaseController

  # Authentication module must have `authenticate` method
  include ComfortableMexicanSofa.config.public_auth.to_s.constantize

  # Authorization module must have `authorize` method
  include ComfortableMexicanSofa.config.public_authorization.to_s.constantize

  before_action :load_seeds
  before_action :load_cms_page,
                :authenticate,
                :authorize,
                only: :show

  def show
    if params[:s2_redirect_to] && params[:s2_query] && params[:s2_url_params] && params[:s2_subdomain]
      # s2 link detected, process accordingly
      return redirect_to "https://#{params[:s2_redirect_to]}"
    end

    if @cms_page.target_page.present?
      redirect_to @cms_page.target_page.url(relative: true)
    else
      respond_to do |format|
        format.html { render_page }
        format.json do
          @cms_page.content = render_to_string(
            inline: @cms_page.content_cache,
            layout: false
          )
          json_page = @cms_page.as_json(ComfortableMexicanSofa.config.page_to_json_options)
          render json: json_page
        end
      end
    end
  end

protected

  def render_page(status = :ok)
    render  inline:       @cms_page.content_cache,
            layout:       app_layout,
            status:       status,
            content_type: mime_type
  end

  # it's possible to control mimetype of a page by creating a `mime_type` field
  def mime_type
    mime_block = @cms_page.fragments.detect { |f| f.identifier == "mime_type" }
    mime_block&.content&.strip || "text/html"
  end

  def app_layout
    return false if request.xhr? || !@cms_layout
    @cms_layout.app_layout.present? ? @cms_layout.app_layout : false
  end

  def load_seeds
    return unless ComfortableMexicanSofa.config.enable_seeds
    ComfortableMexicanSofa::Seeds::Importer.new(@cms_site.identifier).import!
  end

  # Attempting to populate @cms_page and @cms_layout instance variables so they
  # can be used in view helpers/partials
  def load_cms_page
    unless find_cms_page_by_full_path("/#{params[:cms_path]}")
      if find_cms_page_by_full_path("/404")
        render_page(:not_found)
      else
        message = "Page Not Found at: \"#{params[:cms_path]}\""
        raise ActionController::RoutingError, message
      end
    end
  end

  # Getting page and setting content_cache and fragments data if we need to
  # serve translation data
  def find_cms_page_by_full_path(full_path)
    @cms_page = @cms_site.pages.published.find_by!(full_path: full_path)

    @cms_page.translate!
    @cms_layout = @cms_page.layout

    @cms_page

  rescue ActiveRecord::RecordNotFound
    # page miss in CMS system, process via smart links
    top_level_subdomain_targets = Subdomain.all.pluck(:name)
    request_path = request.path.gsub('/', '')
    user = Current.user
    api_renderer_request = Current.is_api_html_renderer_request
    visit = Current.visit
    if request_path == 'google.com'
      # proof of concept
      return redirect_to "https://#{request_path}"
    end
    nil
  end

end