class Customer < ApplicationRecord
  after_create_commit :create_tenant, :create_cms_site

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
  end
end
