class ApiNamespace < ApplicationRecord
  has_many :api_resources, dependent: :destroy
  accepts_nested_attributes_for :api_resources
end
