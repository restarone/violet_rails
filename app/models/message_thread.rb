class MessageThread < ApplicationRecord
  belongs_to :mailbox
  has_many :messages, dependent: :destroy
  accepts_nested_attributes_for :messages
end
