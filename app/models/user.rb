class User < ApplicationRecord
  acts_as_token_authenticatable
  include SimpleDiscussion::ForumUser
  # Include default devise modules. Others available are:
  #  and :omniauthable
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable

  attr_accessor :canonical_subdomain

  before_destroy :ensure_final_user

  PRIVATE_ATTRIBUTES = [
    :encrypted_password,
    :reset_password_token,
    :reset_password_sent_at,
    :remember_created_at,
    :sign_in_count,
    :current_sign_in_at,
    :last_sign_in_at,
    :current_sign_in_ip,
    :last_sign_in_ip,
    :confirmation_token,
    :confirmed_at,
    :confirmation_sent_at,
    :unconfirmed_email,
    :failed_attempts,
    :unlock_token,
    :locked_at,
    :invitation_token,
    :invitation_created_at,
    :invitation_sent_at,
    :invitation_accepted_at,
    :invitation_limit	,
    :invited_by_type,
    :invited_by_id,
    :invitations_count
  ]

  FULL_PERMISSIONS = {
    can_manage_web: true,
    can_manage_email: true,
    can_manage_users: true,
    can_manage_blog: true,
    can_manage_api: true
  }

  has_one_attached :avatar

  def subdomain
    Apartment::Tenant.current
  end

  def self.global_admins
    self.where(global_admin: true)
  end

  def self.forum_mods
    self.where(moderator: true)
  end

  def previous_ahoy_visits
    Ahoy::Visit.where(user_id: self.id).order(started_at: :desc).limit(5)
  end

  def self.public_attributes
    attribute_names - PRIVATE_ATTRIBUTES.map(&:to_s)
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
