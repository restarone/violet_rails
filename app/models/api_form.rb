class ApiForm < ApplicationRecord
  belongs_to :api_namespace

  INPUT_TYPE_MAPPING = {
    free_text: 'free text',
    number: 'number',
    regex_pattern: 'REGEX pattern',
    email: 'email',
    url: 'url',
    date: 'date',
    datetime: 'datetime'
  }
end
