class ApiForm < ApplicationRecord
  belongs_to :api_namespace

  INPUT_TYPE = ['free text', 'number', 'REGEX pattern', 'email', 'url', 'date', 'datetime-local']
end
