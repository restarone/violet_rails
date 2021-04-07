class Subdomain < ApplicationRecord
  validates :name, format: {
    with: %r{\A[a-z](?:[a-z0-9-]*[a-z0-9])?\z}i, message: "not a valid subdomain"
  }, length: { in: 1..63 }, uniqueness: true

  belongs_to :customer

  after_create_commit :create_cms_site

  def hostname
    "#{self.name}.#{ENV['APP_HOST']}"
  end

  private 

  def create_cms_site
    hostname = self.hostname
    Apartment::Tenant.switch(self.name) do
      site = Comfy::Cms::Site.create!(
        identifier: self.name,
        # this is only for local testing
        hostname:   hostname,
      )
      layout = site.layouts.create(
        label: 'default',
        identifier: 'default',
        content: "{{cms:wysiwyg content}}",
        app_layout: 'website'
      )
      page = layout.pages.create(
        site_id: site.id,
        label: 'root',
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
