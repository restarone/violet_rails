class UpdateBootstrapedSubdomainHostname < ActiveRecord::Migration[6.1]
  def change
    Apartment::Tenant.switch('public') do
      site = Comfy::Cms::Site.find_by(hostname: 'www')
      site.update(hostname: ENV['APP_HOST']) if site
    end
  end
end
