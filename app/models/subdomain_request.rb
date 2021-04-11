class SubdomainRequest < ApplicationRecord
  extend FriendlyId
  validate :subdomain_is_available, :is_legal
  validates_format_of :email, with: Devise::email_regexp, if: -> { self.email.present? }

  friendly_id :obfuscation_slugger, use: :slugged

  private

  def obfuscation_slugger
    SecureRandom.hex(10)
  end

  def subdomain_is_available
    if self.subdomain_name.present? && Subdomain.find_by(name: self.subdomain_name)
      errors.add(:subdomain_name, "This subdomain is unavailable!")
    end
  end

  def is_legal
    if self.subdomain_name.present?
      unless Subdomain.new(name: self.subdomain_name).valid?
        errors.add(:subdomain_name, "This subdomain is illegal, please enter a different subdomain name.")
      end
    end
  end
end
