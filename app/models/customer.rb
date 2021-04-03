class Customer < ApplicationRecord
  after_create_commit :create_tenant

  private
  def create_tenant
    Apartment::Tenant.create(self.subdomain)
  end
end
