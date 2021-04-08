class User < ApplicationRecord
  include SimpleDiscussion::ForumUser

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable


  def name
    self.email
  end

  def self.create_clone_for(customer)
    user = self.new(
      email: customer.email, 
      encrypted_password: customer.encrypted_password
    )
    user.save(validate: false)
    return user
  end
end
