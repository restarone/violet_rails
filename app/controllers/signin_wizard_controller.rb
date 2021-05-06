class SigninWizardController < ApplicationController
  include Wicked::Wizard
  steps :set_subdomain

  def show
    render_wizard
  end

  def update
    subdomain = SubdomainRequest.new(subdomain_request_params).subdomain_name
    redirect_to wizard_path(:wicked_finish, {schema: subdomain})
  end

  def finish_wizard_path
    root_url(subdomain: params[:schema])
  end

  private

  def subdomain_request_params
    params.require(:subdomain_request).permit(:subdomain_name)
  end
end
