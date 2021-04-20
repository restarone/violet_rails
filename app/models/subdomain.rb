class Subdomain < ApplicationRecord
  validates :name, format: {
    with: %r{\A[a-z](?:[a-z0-9-]*[a-z0-9])?\z}i, message: "not a valid subdomain"
  }, length: { in: 1..63 }, uniqueness: true

  before_create :downcase_subdomain_name, :create_tenant

  after_create_commit :create_cms_site

  # max 1GB by default storage allowance
  MAXIMUM_STORAGED_ALLOWANCE = 1073741824

  def self.current
    Subdomain.find_by(name: Apartment::Tenant.current)
  end

  def initialize_mailbox
    mailbox = Mailbox.first_or_create
    mailbox.update(enabled: true)
  end

  def hostname
    "#{self.name}.#{ENV['APP_HOST']}"
  end

  def db_configuration
    {
      adapter: 'postgresql',
      host: ENV['DATABASE_HOST'],
      port: ENV['DATABASE_PORT'],
      database: 'postgres'
    }
  end

  def has_enough_storage?
    Subdomain::MAXIMUM_STORAGED_ALLOWANCE - self.storage_used > 0
  end

  def storage_used
    if ActiveStorage::Blob.any?
      return ActiveStorage::Blob.all.pluck(:byte_size).sum
    else
      return 0
    end
  end

  private

  def downcase_subdomain_name
    self.name = self.name.downcase
  end

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

  def create_tenant
    Apartment::Tenant.create(self.name)
  end
end
