class Admin::SubdomainsController < Admin::BaseController
  before_action :load_subdomain, except: [:index, :create, :new]

  def index
    params[:q] ||= {}
    @subdomains_q = Subdomain.ransack(params[:q])
    @subdomains = @subdomains_q.result.paginate(page: params[:page], per_page: 10)
  end

  def create
    subdomain = Subdomain.new(subdomain_params)
    if subdomain.save
      invite_current_user_to_subdomain(subdomain)
      flash.notice = "Subdomain: #{subdomain.name} created!"
      redirect_to admin_subdomains_path
    else
      flash.alert = subdomain.errors.full_messages.to_sentence
      render :new
    end
  end

  def edit

  end

  def new
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

  def invite_current_user_to_subdomain(subdomain)
    Apartment::Tenant.switch subdomain.name do
      User.invite!(email: current_user.email)
    end
  end

  def load_subdomain
    @subdomain = Subdomain.find_by(id: params[:id])
    unless @subdomain
      flash.alert = 'that subdomain couldnt be found'
      redirect_to admin_subdomain_requests_path
    end
  end

  def subdomain_params
    params.require(:subdomain).permit(
      :name,
      :forum_enabled,
      :blog_enabled,
      :allow_user_self_signup,
      :forum_is_private
    )
  end
end
