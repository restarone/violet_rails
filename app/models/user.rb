class User < ApplicationRecord
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

  SESSION_TIMEOUT = [
    {
      label: '1 hour',
      exec: '1.hour',
      slug: '1-hour'
    },
    {
      label: '3 hours',
      exec: '3.hours',
      slug: '3-hour'
    },
    {
      label: '6 hours',
      exec: '6.hours',
      slug: '6-hour'
    },
    {
      label: '1 day',
      exec: '1.day',
      slug: '1-day'
    },
    {
      label: '1 week',
      exec: '1.week',
      slug: '1-week'
    }
  ]

  validates :session_timeoutable_in, inclusion: { in: User::SESSION_TIMEOUT.map{ |n| n[:slug] } }

  has_one_attached :avatar

  # to run User.find(123).visits
  has_many :visits, class_name: "Ahoy::Visit"


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

  def timeout_in
    timeout = User::SESSION_TIMEOUT.detect{|n| n[:slug] == self.session_timeoutable_in }[:exec]
    eval(timeout)
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
