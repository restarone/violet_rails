class Customer < ApplicationRecord
  after_create_commit :create_tenant, :create_cms_site

  def name
    self.subdomain
  end

  private
  def create_tenant
    Apartment::Tenant.create(self.subdomain)
  end

  def create_cms_site
    site = Comfy::Cms::Site.create!(
      identifier: self.subdomain,
      # this is only for local testing
      hostname:   "#{self.subdomain}.lvh.me:3000",
    )
    layout = site.layouts.create(
      label: self.name,
      identifier: self.name,
      content: "{{cms:wysiwyg content}}"
    )
    layout.pages.create(
      site_id: site.id,
      label: self.name,
      content: "<h3>Hello from #{self.subdomain}</h3>"
    )
  end
end
