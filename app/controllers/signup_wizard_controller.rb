class SignupWizardController < ApplicationController
  include Wicked::Wizard
  before_action :set_progress, only: [:show]

  steps :scopes_of_service, :subdomain_name, :sign_up

  def show
    render_wizard
  end

  def finish_wizard_path
    root_url
  end

  private 

  def set_progress
    if wizard_steps.any? && wizard_steps.index(step).present?
      @progress = ((wizard_steps.index(step) + 1).to_d / wizard_steps.count.to_d ) * 100
    else
      @progress = 0
    end
  end
end
