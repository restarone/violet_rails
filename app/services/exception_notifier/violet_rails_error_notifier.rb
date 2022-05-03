module ExceptionNotifier
  class VioletRailsErrorNotifier
    def initialize(options)
    end

    def call(exception, options={})
      # see application controller for data injection/usage example````````````````````````````` `
      # custom_passed_data = options[:env]["exception_notifier.exception_data"]
      notifier = ExceptionNotifier::EmailNotifier.new(
        {
          email_prefix: ENV["APP_HOST"],
          sender_address: "'violet-rails-errors' #{Subdomain.current.name}@#{ENV['APP_HOST']}",
          exception_recipients: User.where(can_recieve_error_notifications: true).pluck(:email)
        }
      )
      notifier.call(exception, options)
    end
  end
end