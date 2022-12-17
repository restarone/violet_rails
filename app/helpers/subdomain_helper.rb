module SubdomainHelper
  def users_count(subdomain)
    Apartment::Tenant.switch subdomain.name do
      User.all.size
    end
  end

  def emails_count(subdomain)
    Apartment::Tenant.switch subdomain.name do
      Message.all.size
    end
  end

  def blog_posts_count(subdomain)
    Apartment::Tenant.switch subdomain.name do
      Comfy::Blog::Post.all.size
    end
  end

  def web_pages_count(subdomain)
    Apartment::Tenant.switch subdomain.name do
      Comfy::Cms::Site.first.pages.size
    end
  end

  def forum_threads_count(subdomain)
    Apartment::Tenant.switch subdomain.name do
      ForumThread.all.size
    end
  end

  def visits_count(subdomain)
    Apartment::Tenant.switch subdomain.name do
      Ahoy::Visit.all.size
    end
  end

  def html_title(subdomain)
    subdomain.html_title ? subdomain.html_title : subdomain.name
  end

  def blog_title(subdomain)
    subdomain.blog_title ? subdomain.blog_title : subdomain.name
  end

  def blog_html_title(subdomain)
    subdomain.blog_html_title ? subdomain.blog_html_title : subdomain.name
  end

  def forum_title(subdomain)
    subdomain.forum_title ? subdomain.forum_title : subdomain.name
  end

  def forum_html_title(subdomain)
    subdomain.forum_html_title ? subdomain.forum_html_title : subdomain.name
  end

  def render_logo(subdomain)
    return if !subdomain.logo.attached?
    image_tag subdomain.logo, class: 'rounded avatar', size: '40x40'
  end

  def logo_url(subdomain)
    return if !subdomain.logo.attached?
    rails_blob_path(subdomain.logo)
  end

  def og_image_url(subdomain)
    # this needs to be an absolute path, not a relative one
    return if !subdomain.og_image.attached?
    rails_blob_url(subdomain.og_image)
  end

  def render_og_image(subdomain)
    return if !subdomain.og_image.attached?
    image_tag subdomain.og_image, class: 'rounded avatar', size: '100x100'
  end


  def render_favicon(subdomain)
    return if !subdomain.favicon.attached?
    image_tag subdomain.favicon, class: 'rounded avatar', size: '40x40'
  end

  def site_description(subdomain)
    subdomain.description ? subdomain.description : subdomain.name
  end

  def site_keywords(subdomain)
    subdomain.keywords ? subdomain.keywords : subdomain.name
  end

  def og_metadata(show_page, api_resource)
      if show_page && api_resource&.api_namespace&.social_share_metadata.present?
        api_namespace = api_resource.api_namespace
        { 
          title: api_resource.properties[api_namespace.social_share_metadata["title"]],
          description: api_resource.properties[api_namespace.social_share_metadata["description"]],
          image: {
            _: api_resource.non_primitive_properties.find_by(field_type: "file", label: api_namespace.social_share_metadata["image"])&.file_url,
            width: 1200,
            height: 628,
          }
        }
      else
        {
          image: og_image_url(Subdomain.current),
          title: html_title(Subdomain.current),
          description: site_description(Subdomain.current)
        }
      end
  end

end
