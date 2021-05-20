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
end
