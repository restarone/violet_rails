Subdomain.all.each do |subdomain|
  subdomain_name = subdomain.name == Subdomain::ROOT_DOMAIN_NAME ? 'www' : subdomain.name
  SitemapGenerator::Sitemap.default_host = "https://#{subdomain_name}.#{ENV['APP_HOST']}"
  SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/#{subdomain_name}"
  SitemapGenerator::Sitemap.create do
    Apartment::Tenant.switch subdomain.name do
      paths = Comfy::Cms::Page.all.pluck(:full_path)
      paths.each do |path|
        add path
      end
    end
  end
end


