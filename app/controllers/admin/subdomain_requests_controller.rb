class Admin::SubdomainRequestsController < Admin::BaseController
  before_action :load_subdomain_request, except: [:index]

  def index
    @subdomain_requests = SubdomainRequest.pending
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
    @subdomain_request.approve!
    flash.notice = "Approved #{@subdomain_request.subdomain_name}!"
    redirect_to admin_subdomain_requests_path 
  end

  def disapprove
    flash.notice = "Disapproved #{@subdomain_request.subdomain_name}!"
    @subdomain_request.disapprove!
    redirect_to admin_subdomain_requests_path 
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
