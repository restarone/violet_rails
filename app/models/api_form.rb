class ApiForm < ApplicationRecord
  belongs_to :api_namespace

  INPUT_TYPE_MAPPING = {
    free_text: 'free_text',
    number: 'number',
    regex_pattern: 'regex_pattern',
    email: 'email',
    url: 'url',
    date: 'date',
    datetime: 'datetime'
  }
end
