class ContentController < ApplicationController
  before_action :load_seo_vars

  def load_seo_vars
    @page_title       = helpers.html_title(Subdomain.current)
    @page_description = helpers.site_description(Subdomain.current)
    @page_keywords    = helpers.site_keywords(Subdomain.current)
    image_path = helpers.logo_url(Subdomain.current)
    set_meta_tags(
      og: {
        image: image_path,
        title: @page_title,
        description: @page_description
      },
      twitter: {
        image: {
          _: image_path,
          width: 1200,
          height: 628,
        },
        card: 'summary_large_image',
      }
    )
  end
end
