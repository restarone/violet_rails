class ApiForm < ApplicationRecord
  include JsonbFieldsParsable
  belongs_to :api_namespace

  before_save :mutually_exclude_recaptcha_type, if: -> { self.show_recaptcha && self.show_recaptcha_v3 }

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

  RECAPTCHA_V3_MINIMUM_SCORE = 0.5

  def is_field_renderable?(field)
    properties.dig(field.to_s, 'renderable').nil? || properties.dig(field.to_s, 'renderable') == '1'
  end

  private

  def mutually_exclude_recaptcha_type
    self.show_recaptcha_v3 = false
  end
end
