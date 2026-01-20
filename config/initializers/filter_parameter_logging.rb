# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [
  :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :email, :otp_secret, :encrypted_otp_secret_salt, :encrypted_otp_secret_iv, :"warden.user.user.key", :"_csrf_token"
]
