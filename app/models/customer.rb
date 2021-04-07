class Customer < ApplicationRecord
  # Include default devise modules. Others available are:
  # :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable, :lockable, :timeoutable, :trackable

  attr_accessor :subdomain

  has_many :subdomains, dependent: :destroy

  after_create :create_tenant, :create_first_subdomain
  after_destroy :drop_tenant

  def confirm_email!
    self.update(confirmed_at: Time.now)
  end
  

  def name
    self.subdomains.first.name
  end

  private

  def drop_tenant
    self.subdomains.each do |subdomain|
      Apartment::Tenant.drop(subdomain.name)
    end
  end

  def create_tenant
    Apartment::Tenant.create(self.subdomain)
  end

  def create_first_subdomain
    self.subdomains.create(name: self.subdomain)
  end
end
