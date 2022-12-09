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

# Rails.application.config.active_storage.service_urls_expire_in = 5.hour