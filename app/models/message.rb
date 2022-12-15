class Message < ApplicationRecord
  validates :content, presence: true

  belongs_to :message_thread
  accepts_nested_attributes_for :message_thread

  has_rich_text :content
  has_one :content, class_name: 'ActionText::RichText', as: :record
  has_many_attached :attachments

  default_scope { order(created_at: 'DESC') }

  before_save :generate_message_id
  after_create :update_message_thread_current_email_message_id
  after_create_commit :deliver

  private

  def generate_message_id
    if self.email_message_id.blank?
      self.email_message_id = "#{Digest::SHA2.hexdigest(Time.now.to_i.to_s)}.#{Apartment::Tenant.current}@#{ENV['APP_HOST']}"
    end
  end

  def update_message_thread_current_email_message_id
    if self.message_thread
      self.message_thread.update(current_email_message_id: self.email_message_id)
    end
  end

  def deliver
    if !self.from
      # if there is no from attribute, we can assume that its an outgoing message
      EMailer.with(message: self, message_thread: self.message_thread).ship.deliver_later
    end
  end
end
