class Customer < ApplicationRecord
  # Include default devise modules. Others available are:
  # :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable, :lockable, :timeoutable, :trackable

  attr_accessor :subdomain

  has_many :subdomains

  after_create :create_tenant, :create_first_subdomain
  

  def name
    self.subdomains.first.name
  end

  private
  def create_tenant
    Apartment::Tenant.create(self.subdomain)
  end

  def create_first_subdomain
    self.subdomains.create(name: self.subdomain)
  end
end
