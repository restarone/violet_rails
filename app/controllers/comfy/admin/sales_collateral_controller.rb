class Comfy::Admin::SalesCollateralController < Comfy::Admin::Cms::BaseController
  before_action :ensure_authority_to_manage_analytics

  def dashboard
    # Get the host
    subdomain = Apartment::Tenant.current
    subdomain_resolved_for_apex = subdomain == 'public' || subdomain == 'root' ? "https://#{ENV['APP_HOST']}" : "https://#{subdomain}.#{ENV['APP_HOST']}" 
    host = subdomain_resolved_for_apex
    email_resolved_for_apex = subdomain == 'public' || subdomain == 'root' ? "public@#{ENV['APP_HOST']}" : "#{subdomain}@#{ENV['APP_HOST']}" 
    @website = host
    @email = email_resolved_for_apex
  end

  def generate
    subdomain = Subdomain.current
    subdomain.generate_default_sales_assets
    redirect_to sales_collateral_path
  end
end