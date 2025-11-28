class Shortcut < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged
  validates :name, presence: true
  validates :path, presence: true
  
  belongs_to :subdomain
end
