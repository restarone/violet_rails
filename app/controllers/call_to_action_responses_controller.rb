class CallToActionResponsesController < ApplicationController
  def respond
    # verify_recaptcha(model: @call_to_action)
    byebug
  end

  private
  def set_call_to_action
    @call_to_action = CallToAction.find(params[:id])
  end
end
