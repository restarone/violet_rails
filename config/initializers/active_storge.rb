if Rails.env == 'production' || Rails.env == 'test'
  require 'active_storage/attachment'

  class ActiveStorage::Attachment
    before_save :ensure_storage_limit_not_exceeded

    def ensure_storage_limit_not_exceeded
      unless Subdomain.current.has_enough_storage?
        errors.add(:subdomain, 'out of storage')
        throw(:abort)
      end
    end
  end
end

if ENV['OLD_SECRET_KEY_BASE'].present?
  Rails.application.config.after_initialize do |app|
    key_generator =  ActiveSupport::KeyGenerator.new(ENV['OLD_SECRET_KEY_BASE'], iterations: 1000, hash_digest_class: OpenSSL::Digest::SHA1)
    secret = key_generator.generate_key("ActiveStorage")
    app.message_verifier("ActiveStorage").rotate(secret)
  end
end

