require 'exception_notification/rails'

require 'exception_notification/sidekiq'



ExceptionNotification.configure do |config|
  # Ignore additional exception types.
  # ActiveRecord::RecordNotFound, Mongoid::Errors::DocumentNotFound, AbstractController::ActionNotFound and ActionController::RoutingError are already added.
  config.ignored_exceptions += %w{ActionController::ParameterMissing ActionController::RoutingError ActionController::InvalidAuthenticityToken ActionDispatch::Http::MimeNegotiation::InvalidType ActiveRecord::RecordNotFound}

  # Adds a condition to decide when an exception must be ignored or not.
  # The ignore_if method can be invoked multiple times to add extra conditions.
  # config.ignore_if do |exception, options|
  #   not Rails.env.production?
  # end

  # Ignore exceptions generated by crawlers
  config.ignore_crawlers %w{Googlebot bingbot}

  # Notifiers =================================================================

  # app/services/exception_notifier/violet_rails_error_notifier.rb
  config.add_notifier :violet_rails_error, {
    app: {
      host: ENV["APP_HOST"]
    }
  }

  # Campfire notifier sends notifications to your Campfire room. Requires 'tinder' gem.
  # config.add_notifier :campfire, {
  #   subdomain: 'my_subdomain',
  #   token: 'my_token',
  #   room_name: 'my_room'
  # }

  # HipChat notifier sends notifications to your HipChat room. Requires 'hipchat' gem.
  # config.add_notifier :hipchat, {
  #   api_token: 'my_token',
  #   room_name: 'my_room'
  # }

  # Webhook notifier sends notifications over HTTP protocol. Requires 'httparty' gem.
  # config.add_notifier :webhook, {
  #   url: 'http://example.com:5555/hubot/path',
  #   http_method: :post
  # }
end
