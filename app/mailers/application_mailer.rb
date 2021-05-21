class ApplicationMailer < ActionMailer::Base
  default from: "#{Apartment::Tenant.current}@#{ENV['APP_HOST']}"
  default "Message-ID" => lambda {" #{Digest::SHA2.hexdigest(Time.now.to_i.to_s)}@#{Rails.application.config.action_mailer.mailgun_settings[:domain]} "}
end
