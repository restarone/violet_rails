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

  def success_message_has_html?
    success_message.present? && Nokogiri::XML(success_message).errors.empty?
  end

  def failure_message_has_html?
    failure_message.present? && Nokogiri::XML(failure_message).errors.empty?
  end
end
