class ApiForm < ApplicationRecord
  include JsonbFieldsParsable
  belongs_to :api_namespace

  INPUT_TYPE_MAPPING = {
    free_text: 'text',
    number: 'number',
    regex_pattern: 'regex_pattern',
    email: 'email',
    url: 'url',
    date: 'date',
    datetime: 'datetime-local',
    tel: 'tel'
  }

  def is_field_renderable?(field)
    properties.dig(field.to_s, 'renderable').nil? || properties.dig(field.to_s, 'renderable') == '1'
  end
end
