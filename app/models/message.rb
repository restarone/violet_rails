class Message < ApplicationRecord
  has_rich_text :content
  has_many_attached :attachments
end
