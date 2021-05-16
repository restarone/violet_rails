class SubdomainRequest < ApplicationRecord
  extend FriendlyId
  validate :subdomain_is_available, :is_legal
  validates_format_of :email, with: Devise::email_regexp, if: -> { self.email.present? }

  friendly_id :obfuscation_slugger, use: :slugged

  validate :can_be_approved?, if: -> { self.approved_changed? }

  after_save :spawn_subdomain, :destroy_request, if: -> { self.approved? }

  def self.pending
    self.where(approved: false)
  end

  def approve!
    self.update(approved: true)
  end

  def disapprove!
    self.destroy
  end

  private

  def spawn_subdomain
    subdomain = Subdomain.create! name: self.subdomain_name
    Apartment::Tenant.switch subdomain.name do 
      user = User.invite!(email: self.email)
      # confer default ownership rights of that subdomain
      user.update(User::FULL_PERMISSIONS)
      spawn_emailbox
    end
  end

  def spawn_emailbox
    subdomain = Subdomain.find_by(name: self.subdomain_name)
    Apartment::Tenant.switch subdomain.name do 
      mailbox = subdomain.initialize_mailbox
    end
  end

  def destroy_request
    self.destroy
  end

  def can_be_approved?
    subdomain = Subdomain.new(name: self.subdomain_name)
    unless subdomain.valid?
      errors.add(:subdomain_name, "A subdomain cannot be created with this request!")
    end

    unless self.email
      errors.add(:email, "A subdomain cannot be assigned without a canonical user!")
    end
  end

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
