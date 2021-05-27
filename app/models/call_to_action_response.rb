class CallToActionResponse < ApplicationRecord
  belongs_to :call_to_action
  attr_accessor :name, :email, :phone, :message
end
