class Message < ApplicationRecord
  validates :content, presence: true

  belongs_to :message_thread
  accepts_nested_attributes_for :message_thread

  has_rich_text :content
  has_one :content, class_name: 'ActionText::RichText', as: :record
  has_many_attached :attachments

  default_scope { order(created_at: 'DESC') }

  after_create_commit :deliver

  private

  def deliver
    if !self.from
      # if there is no from attribute, we can assume that its an outgoing message
      EMailer.with(message: self, message_thread: self.message_thread).ship.deliver_later
    end
  end
end
