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
end
