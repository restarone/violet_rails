class SubdomainRequest < ApplicationRecord
  validate :subdomain_is_available, :is_legal
  validates :subdomain_name, presence: true
  validates_format_of :email, with: Devise::email_regexp

  private

  def subdomain_is_available
    if Subdomain.find_by(name: self.subdomain_name)
      errors.add(:subdomain_name, "This subdomain is unavailable!")
    end
  end

  def is_legal
    unless Subdomain.new(name: self.subdomain_name).valid?
      errors.add(:subdomain_name, "This subdomain is illegal, please enter a different subdomain name.")
    end
  end
end
