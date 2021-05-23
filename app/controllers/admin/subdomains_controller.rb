class Admin::SubdomainsController < Admin::BaseController
  before_action :load_subdomain, except: [:index]

  def index
    params[:q] ||= {}
    @subdomains_q = Subdomain.ransack(params[:q])
    @subdomains = @subdomains_q.result.paginate(page: params[:page], per_page: 10)
  end

  def edit

  end

  def update

  end

  def destroy
    if @subdomain.destroy
      flash.notice = "#{@subdomain.name} has been destroyed!"
    else
      flash.error = "#{@subdomain.name} could not be destroyed!"
    end
    redirect_to admin_subdomains_path
  end

  private 

  def load_subdomain
    @subdomain = Subdomain.find_by(id: params[:id])
    unless @subdomain
      flash.alert = 'that subdomain couldnt be found'
      redirect_to admin_subdomain_requests_path
    end
  end
end
