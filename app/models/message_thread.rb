class MessageThread < ApplicationRecord
  validates :recipients, presence: true, length: { minimum: 1 }
  has_many :messages, dependent: :destroy
  accepts_nested_attributes_for :messages

  scope :search_messages_content_body_or_subject_or_messages_from_or_recipients_contains,->(value) {
    value = "%#{value}%"
  
    left_outer_joins(messages: :content)
    .where('action_text_rich_texts.body ILIKE ? OR message_threads.subject ILIKE ? OR messages.from ILIKE ? OR message_threads.recipients::text ILIKE ?', value, value, value, value)
    .distinct
  }

  private

  def self.ransackable_scopes(auth_object = nil)
    [:search_messages_content_body_or_subject_or_messages_from_or_recipients_contains]
  end
end
