class Customer < ApplicationRecord
  after_create :create_tenant
  after_create_commit :create_cms_site

  def name
    self.subdomain
  end

  private
  def create_tenant
    Apartment::Tenant.create(self.subdomain)
  end

  def create_cms_site
    hostname = "#{self.subdomain}.lvh.me:3000"
    Apartment::Tenant.switch(self.subdomain) do
      site = Comfy::Cms::Site.create!(
        identifier: self.subdomain,
        # this is only for local testing
        hostname:   hostname,
      )
      layout = site.layouts.create(
        label: self.name,
        identifier: self.name,
        content: "{{cms:wysiwyg content}}"
      )
      page = layout.pages.create(
        site_id: site.id,
        label: self.name,
      )
      Comfy::Cms::Fragment.create!(
        identifier: 'content',
        record: page,
        tag: 'wysiwyg',
        content: "
          <div>
            <h1>Hello from #{self.name}</h1>
            To access the admin panel for your website, 
            <a href='http://#{hostname}/admin' target='_blank'>click here</a>
          </div>
        "
      )
    end
  end
end
