# frozen_string_literal: true

require "comfy_bootstrap_form/form_builder"
require "comfy_bootstrap_form/view_helper"

module ComfyBootstrapForm
  module Rails
    class Engine < ::Rails::Engine
    end
  end
end

ActiveSupport.on_load(:action_view) do
  include ComfyBootstrapForm::ViewHelper
end
