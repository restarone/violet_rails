class Message < ApplicationRecord
  belongs_to :message_thread
  accepts_nested_attributes_for :message_thread

  has_rich_text :content
  has_many_attached :attachments

  default_scope { order(created_at: 'DESC') }
end
