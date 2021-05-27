class CallToAction < ApplicationRecord
  has_rich_text :content

  ACTION_TYPES = {
    contact_us: 'contact-us',
    collect_email: 'collect-email',
  }

  has_many :call_to_action_responses
  accepts_nested_attributes_for :call_to_action_responses

  validates :cta_type, inclusion: { in: CallToAction::ACTION_TYPES.values }
end
