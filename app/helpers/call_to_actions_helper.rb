module CallToActionsHelper

  def render_call_to_action(id)
    # usage in cms  {{ cms:helper render_call_to_action, 1 }} here 1 is the id
    @call_to_action = CallToAction.find_by(id: id)
    if @call_to_action
      @call_to_action_response = @call_to_action.call_to_action_responses.new
      render partial: 'comfy/admin/call_to_actions/render'
    end
  end
end
