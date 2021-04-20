class Mailbox < ApplicationRecord
  has_many :message_threads, dependent: :destroy
end
