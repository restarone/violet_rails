class DeviseMailer < Devise::Mailer
  default from: "#{Subdomain.current.name} #{Subdomain.current.html_title} <#{Subdomain.current.name}@#{ENV['APP_HOST']}>"
  default "Message-ID" => lambda {"#{Digest::SHA2.hexdigest(Time.now.to_i.to_s)}@#{ENV['APP_HOST']}"}
end