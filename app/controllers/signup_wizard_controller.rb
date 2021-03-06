class SignupWizardController < ApplicationController
  include Wicked::Wizard
  before_action :set_progress, only: [:show]

  before_action :load_subdomain_request, only: [:show, :update]

  steps :scopes_of_service, :subdomain_name, :sign_up

  def show
    render_wizard
  end

  def create
    @subdomain_request = SubdomainRequest.new(subdomain_request_params)
    if @subdomain_request.save
      redirect_to wizard_path(:subdomain_name, {subdomain_request_id: @subdomain_request.slug})
    end
  end

  def update
    case step
    when :subdomain_name
      if @subdomain_request.update(subdomain_request_params)
        redirect_to wizard_path(:sign_up, {subdomain_request_id: @subdomain_request.slug})
      else
        render_wizard
      end
    when :sign_up
      if verify_recaptcha(model: @subdomain_request) && @subdomain_request.update(subdomain_request_params)
        flash.notice = 'Thanks! We will send you your login link once you have been approved!'
        redirect_to wizard_path(:wicked_finish)
      else
        render_wizard
      end
    end
  end

  def finish_wizard_path
    root_url
  end

  private 
  
  def load_subdomain_request
    if params[:subdomain_request_id]
      @subdomain_request = SubdomainRequest.find_by(slug: params[:subdomain_request_id])
    end
  end

  def subdomain_request_params
    params.require(:subdomain_request).permit(:requires_web, :requires_blog, :requires_forum, :email, :subdomain_name)
  end


  def set_progress
    if wizard_steps.any? && wizard_steps.index(step).present?
      @progress = ((wizard_steps.index(step) + 1).to_d / wizard_steps.count.to_d ) * 100
    else
      @progress = 0
    end
  end
end
