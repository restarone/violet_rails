class CallToActionResponsesController < ApplicationController
  before_action :set_call_to_action, only: [:respond]
  def respond
    if verify_recaptcha(model: @call_to_action) && build_response && @call_to_action_response.save
      flash.notice = @call_to_action.success_message
    else
      flash.alert = @call_to_action.failure_message
    end
    redirect_back(fallback_location: root_path)
  end

  private

  def build_response
    @call_to_action_response = @call_to_action.call_to_action_responses.new(properties: call_to_action_params[:call_to_action_response])
  end

  def call_to_action_params
    params.require(:call_to_action).permit(
      call_to_action_response: CallToActionResponse::ATTRIBUTE_MAPPING.keys
    )
  end

  def set_call_to_action
    @call_to_action = CallToAction.find(params[:id])
  end
end
