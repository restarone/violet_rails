class MessageThread < ApplicationRecord
  belongs_to :mailbox
  has_many :messages, dependent: :destroy
end
