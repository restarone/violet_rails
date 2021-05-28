class CallToActionResponse < ApplicationRecord
  belongs_to :call_to_action
  ATTRIBUTE_MAPPING = {
    name: 'name',
    email: 'email',
    phone: 'phone',
    message: 'message'
  }
  attr_accessor *ATTRIBUTE_MAPPING.keys
end
