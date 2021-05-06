class MessageThread < ApplicationRecord
  validates :recipients, presence: true, length: { minimum: 1 }
  has_many :messages, dependent: :destroy
  accepts_nested_attributes_for :messages
end
