class User < ApplicationRecord
  # Include default devise modules. Others available are:
  #  and :omniauthable
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable


  has_many :email_aliases, dependent: :destroy
  accepts_nested_attributes_for :email_aliases
  has_one :mailbox, dependent: :destroy

  attr_accessor :canonical_subdomain

  after_save :initialize_mailbox, if: -> { self.can_manage_email }
  before_destroy :ensure_final_user

  FULL_PERMISSIONS = {
    can_manage_web: true,
    can_manage_email: true,
    can_manage_users: true,
    can_manage_blog: true,
  }
  
  def subdomain
    Apartment::Tenant.current
  end

  
  def initialize_mailbox
    if self.can_manage_email
      mailbox = Mailbox.first_or_create(user_id: self.id)
      mailbox.update(enabled: true)
    end
  end

  private


  def ensure_final_user
    if Rails.env != 'test'
      if User.all.size - 1 == 0
        throw :abort
      end 
    end
  end
end
