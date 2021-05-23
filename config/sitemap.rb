




Subdomain.all.each do |subdomain|
  subdomain_name = subdomain.name == Subdomain::ROOT_DOMAIN_NAME ? 'www' : subdomain.name
  sitemap_path = "sitemaps/#{subdomain_name}/sitemap.xml.gz"
  SitemapGenerator::Sitemap.default_host = "https://#{subdomain_name}.#{ENV['APP_HOST']}"
  SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/#{subdomain_name}"
  SitemapGenerator::Sitemap.create do
    Apartment::Tenant.switch subdomain.name do
      cms_site = Comfy::Cms::Site.first
      web_paths = Comfy::Cms::Page.all.pluck(:full_path)
      blog_paths = Comfy::Blog::Post.all.map{|post| comfy_blog_post_path(cms_site.path, post.year, post.month, post.slug) }
      # the elegant way to generate the path is to use simple_discussion.forum_thread_path(forum_thread) but that is not in scope right now, so I am constructing the path by hand
      forum_thread_paths = ForumThread.all.map{|forum_thread| "/forum/threads/#{forum_thread.slug}" }

      (web_paths + blog_paths + forum_thread_paths).each do |path|
        add path
      end
      SitemapGenerator::Sitemap.ping_search_engines("https://#{subdomain_name}.#{ENV['APP_HOST']}#{sitemap_path}")
    end
  end
end


