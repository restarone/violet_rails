class DeviseMailer < Devise::Mailer
  default "Message-ID" => lambda {"#{Digest::SHA2.hexdigest(Time.now.to_i.to_s)}@#{ENV['APP_HOST']}"}
end