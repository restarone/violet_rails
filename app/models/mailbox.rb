class Mailbox < ApplicationRecord
  belongs_to :user
  has_many :message_threads, dependent: :destroy
end
