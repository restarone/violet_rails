class Subdomain < ApplicationRecord
  validates :name, format: {
    with: %r{\A[a-z](?:[a-z0-9-]*[a-z0-9])?\z}i, message: "not a valid subdomain"
  }, length: { in: 1..63 }, uniqueness: true

  before_create :downcase_subdomain_name, :create_tenant

  after_create_commit :create_cms_site
  before_destroy :drop_tenant

  has_one_attached :logo
  has_one_attached :favicon
  has_one_attached :og_image


  # max 1GB by default storage allowance
  MAXIMUM_STORAGED_ALLOWANCE = 1073741824
  # www/domain apex maps to public schema. So to recieve email on public schema we need a subdomain. it will be www
  ROOT_DOMAIN_EMAIL_NAME = 'www'

  # root domain name schema name
  ROOT_DOMAIN_NAME = 'www'

  # keep these urls out of logging
  PRIVATE_URL_PATHS  = ['/users/password', '/users/registration', '/users/sessions', '/users/confirmation', '/users/invitation']

  def self.current
    subdomain = Subdomain.find_by(name: Apartment::Tenant.current)
    if subdomain
      subdomain
    else
      domain = Subdomain.find_by(name: Subdomain::ROOT_DOMAIN_NAME) 
      if domain
        domain
      else
        Subdomain.unsafe_bootstrap_root_domain
      end
    end
  end

  def ahoy_visits
    Ahoy::Visit.order(started_at: :desc)
  end

  def initialize_mailbox
    Apartment::Tenant.switch self.name do
      mailbox = Mailbox.first_or_create
      mailbox.update(enabled: true)
    end
  end

  def mailing_address
    Apartment::Tenant.switch self.name do
      "#{Apartment::Tenant.current}@#{ENV['APP_HOST']}"
    end
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
    Apartment::Tenant.switch self.name do
      if ActiveStorage::Blob.any?
        return ActiveStorage::Blob.all.pluck(:byte_size).sum
      else
        return 0
      end
    end
  end

  def destroy
    raise "Cannot destroy root domain" if self.name == Subdomain::ROOT_DOMAIN_NAME
    super
  end

  def self.unsafe_bootstrap_www_subdomain
    Apartment::Tenant.switch('public') do
      Subdomain.bootstrap_via_comfy('public', 'www')
    end 
  end

  def self.unsafe_bootstrap_root_domain
    Subdomain.create!(
      name: Subdomain::ROOT_DOMAIN_NAME,
      html_title: ENV['APP_HOST_HTML_TITLE'] ? ENV['APP_HOST_HTML_TITLE'] : ENV['APP_HOST'],
      blog_title: ENV['APP_HOST_BLOG_TITLE'] ? ENV['APP_HOST_BLOG_TITLE'] : ENV['APP_HOST'],
      blog_html_title: ENV['APP_HOST_BLOG_HTML_TITLE'] ? ENV['APP_HOST_BLOG_HTML_TITLE'] : ENV['APP_HOST'],
      forum_title: ENV['APP_HOST_FORUM_TITLE'] ? ENV['APP_HOST_FORUM_TITLE'] : ENV['APP_HOST'],
      forum_html_title: ENV['APP_HOST_FORUM_HTML_TITLE'] ? ENV['APP_HOST_FORUM_HTML_TITLE'] : ENV['APP_HOST'],
    )
  end

  private

  def drop_tenant
    Apartment::Tenant.drop(self.name)
  end

  def downcase_subdomain_name
    self.name = self.name.downcase
  end

  def create_cms_site
    hostname = self.hostname
    Apartment::Tenant.switch(self.name) do
      Subdomain.bootstrap_via_comfy(self.name, hostname)
    end
  end

  def self.bootstrap_via_comfy(name, hostname)

    site = Comfy::Cms::Site.create!(
      identifier: name,
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
          <h1>Hello from #{name}</h1>
          To access the admin panel for your website, 
          <a href='/admin' target='_blank'>click here</a>
        </div>
      "
    )
  end

  def create_tenant
    Apartment::Tenant.create(self.name)
  end
end
