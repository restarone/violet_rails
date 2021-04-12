class User < ApplicationRecord
  # Include default devise modules. Others available are:
  #  and :omniauthable
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable

  attr_accessor :canonical_subdomain
  
  def subdomain
    Apartment::Tenant.current
  end
end
