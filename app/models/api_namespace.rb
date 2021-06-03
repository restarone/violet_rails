class ApiNamespace < ApplicationRecord
  has_many :api_resources, dependent: :destroy
end
