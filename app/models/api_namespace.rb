class ApiNamespace < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  attr_accessor :has_form

  after_save :update_api_form
  
  has_many :api_resources, dependent: :destroy
  accepts_nested_attributes_for :api_resources

  has_one :api_form, dependent: :destroy
  accepts_nested_attributes_for :api_form

  has_many :api_clients, dependent: :destroy
  accepts_nested_attributes_for :api_clients

  has_many :non_primitive_properties, dependent: :destroy
  accepts_nested_attributes_for :non_primitive_properties, allow_destroy: true

  def update_api_form
    if has_form == '1'
      if api_form.present? 
        api_form.update({ properties: form_properties })
      else
        create_api_form({ properties: form_properties })
      end
    elsif has_form == '0' && api_form.present?
      api_form.destroy
    end
  end

  def form_properties
    form_hash = {}
    form_properties = api_form.present? ? api_form.properties : {}
    JSON.parse(properties).each do |key, _value|
      form_hash[key] = form_properties[key].present? ? form_properties[key] : { label: key.humanize, placeholder: '', required: false }
    end
    non_primitive_properties.each do |prop|
      form_hash[prop.label] = form_properties[prop.label].present? ? form_properties[prop.label] : { label: prop.label.humanize, required: false, prepopulate: '0' }
    end
    form_hash
  end
end
