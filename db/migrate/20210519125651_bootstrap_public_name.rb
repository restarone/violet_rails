class BootstrapPublicName < ActiveRecord::Migration[6.1]
  def change
    Apartment::Tenant.switch('public') do
      Subdomain.unsafe_bootstrap_www_subdomain
    end
  end
end
