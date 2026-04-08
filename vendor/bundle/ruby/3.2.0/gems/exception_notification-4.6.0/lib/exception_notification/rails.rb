# frozen_string_literal: true

# Warning: This must be required after rails but before initializers have been run. If you require
# it from config/initializers/exception_notification.rb, then the rails and rake_task callbacks
# registered here will have no effect, because Rails will have already invoked all registered rails
# and rake_tasks handlers.

module ExceptionNotification
  class Engine < ::Rails::Engine
    config.exception_notification = ExceptionNotifier
    config.exception_notification.logger = Rails.logger
    config.exception_notification.error_grouping_cache = Rails.cache

    config.app_middleware.use ExceptionNotification::Rack

    rake_tasks do
      # Report exceptions occurring in Rake tasks.
      require 'exception_notification/rake'
    end

    runner do
      # Report exceptions occurring in runner commands.
      require 'exception_notification/rails/runner_tie'
      Rails::RunnerTie.new.call
    end
  end
end
