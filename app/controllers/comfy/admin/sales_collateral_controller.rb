class Comfy::Admin::SalesCollateralController < Comfy::Admin::Cms::BaseController
  before_action :ensure_authority_to_manage_analytics

  before_action :load_qr_code, on: [:dashboard]

  def dashboard
    # Get the host
    subdomain = Apartment::Tenant.current
    subdomain_resolved_for_apex = subdomain == 'public' || subdomain == 'root' ? "https://#{ENV['APP_HOST']}" : "https://#{subdomain}.#{ENV['APP_HOST']}" 
    host = subdomain_resolved_for_apex
    email_resolved_for_apex = subdomain == 'public' || subdomain == 'root' ? "public@#{ENV['APP_HOST']}" : "#{subdomain}@#{ENV['APP_HOST']}" 
    @website = host
    @email = email_resolved_for_apex
  end

  def index
    @sales_assets = SalesAsset.all
  end

  def create
    sales_asset = SalesAsset.create!(
      name: params[:name],
      width: params[:width].to_i,
      height: params[:height].to_i,
      html: params[:html],
    )
    flash.notice = "#{sales_asset.name} created!"
    redirect_to edit_sales_collateral_path(sales_asset.id)
  end

  def edit
    id = params[:id]
    @sales_asset = SalesAsset.find(id)
  end

  def update
    id = params[:id]
    @sales_asset = SalesAsset.find(id)
    @sales_asset.update!(
      name: params[:sales_asset][:name],
      width: params[:sales_asset][:width].to_i,
      height: params[:sales_asset][:height].to_i,
      html: params[:sales_asset][:html],
    )
    flash.notice = "#{@sales_asset.name} updated!"
    redirect_to edit_sales_collateral_path(@sales_asset.id)
  end

  def export
    id = params[:id]
    @sales_asset = SalesAsset.find(id)
    binary_output = @sales_asset.render
    send_data binary_output, type: 'image/jpeg', disposition: 'attachment', filename: "#{@sales_asset.name}.jpg"
  end

  def destroy
    id = params[:id]
    @sales_asset = SalesAsset.find(id)
    flash.notice = "#{@sales_asset.name} deleted!"
    @sales_asset.destroy!
    redirect_to sales_collateral_index_path
  end

  private

  def load_qr_code
    Subdomain.current.subdomain_qr_code
  end

end