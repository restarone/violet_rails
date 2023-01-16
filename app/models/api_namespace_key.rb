class ApiNamespaceKey < ApplicationRecord
  belongs_to :api_namespace
  belongs_to :api_key
end
