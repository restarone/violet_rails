class Admin::SubdomainRequestsController < Admin::BaseController
  before_action :load_subdomain_request, only: [:edit, :show, :update, :destroy]

  def index
    @subdomain_requests = SubdomainRequest.all
  end

  def edit

  end

  def show

  end

  def update

  end

  def destroy

  end

  def approve

  end

  def disapprove

  end

  private 

  def load_subdomain_request
    @subdomain_request = SubdomainRequest.find_by(slug: params[:id])
    unless @subdomain_request
      flash.alert = 'that subdomain request couldnt be found'
      redirect_to admin_subdomain_requests_path
    end
  end
end
