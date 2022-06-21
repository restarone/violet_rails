class ApiForm < ApplicationRecord
  include JsonbFieldsParsable
  include DynamicAttribute

  attr_dynamic :success_message, :failure_message

  belongs_to :api_namespace

  before_save :mutually_exclude_recaptcha_type, if: -> { self.show_recaptcha && self.show_recaptcha_v3 }

  attr_accessor :api_resource

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

  # reference: https://developers.google.com/recaptcha/docs/v3#interpreting_the_score
  RECAPTCHA_V3_MINIMUM_SCORE = 0.5

  def is_field_renderable?(field)
    properties.dig(field.to_s, 'renderable').nil? || properties.dig(field.to_s, 'renderable') == '1'
  end

  def success_message_has_html?
    success_message.present? && Nokogiri::XML(success_message).errors.empty?
  end

  def failure_message_has_html?
    failure_message.present? && Nokogiri::XML(failure_message).errors.empty?
  end

  private

  def mutually_exclude_recaptcha_type
    self.show_recaptcha_v3 = false
  end
end
