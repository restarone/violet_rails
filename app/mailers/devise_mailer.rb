class DeviseMailer < Devise::Mailer
  default from: "#{Apartment::Tenant.current} <#{Apartment::Tenant.current}@#{ENV['APP_HOST']}>"
  default "Message-ID" => lambda {"#{Digest::SHA2.hexdigest(Time.now.to_i.to_s)}@#{ENV['APP_HOST']}"}
end