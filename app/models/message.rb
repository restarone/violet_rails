class Message < ApplicationRecord
  validates :content, presence: true

  belongs_to :message_thread
  accepts_nested_attributes_for :message_thread

  has_rich_text :content
  has_many_attached :attachments

  default_scope { order(created_at: 'DESC') }

  after_create_commit :deliver

  private

  def deliver
    EMailer.with(message: self, message_thread: self.message_thread).ship.deliver_later
  end
end
