class Customer < ApplicationRecord
  # Include default devise modules. Others available are:
  # :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable, :lockable, :timeoutable, :trackable


  validates :subdomain, format: {
    with: %r{\A[a-z](?:[a-z0-9-]*[a-z0-9])?\z}i, message: "not a valid subdomain"
  }, length: { in: 1..63 }, uniqueness: true

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
