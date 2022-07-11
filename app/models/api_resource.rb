class ApiResource < ApplicationRecord
  include JsonbFieldsParsable

  after_initialize :inherit_properties_from_parent

  belongs_to :api_namespace

  before_create :inject_inherited_properties

  after_create :initialize_api_actions, :perform_model_layer_api_actions

  validate :presence_of_required_properties

  has_many :non_primitive_properties, dependent: :destroy
  accepts_nested_attributes_for :non_primitive_properties, allow_destroy: true

  has_many :api_actions, dependent: :destroy

  has_many :new_api_actions, dependent: :destroy

  has_many :create_api_actions, dependent: :destroy

  has_many :show_api_actions, dependent: :destroy

  has_many :update_api_actions, dependent: :destroy

  has_many :destroy_api_actions, dependent: :destroy

  has_many :error_api_actions, dependent: :destroy

  ransacker :properties do |_parent|
    Arel.sql("api_resources.properties::text") 
  end

  def properties_object
    JSON.parse(properties.to_json, object_class: OpenStruct)
  end

  def presence_of_required_properties
    return unless api_namespace.api_form && properties&.is_a?(Enumerable)

    properties.each do |key, value|
      if api_namespace.api_form.properties.dig(key,"required") == '1' && !value.present?
        errors.add(:properties, "#{key} is required")
      end
    end
  end

  private

  def perform_model_layer_api_actions
    self.create_api_actions.where(action_type: ["send_web_request", "send_email"]).each{|action| action.execute_action}
  end

  def initialize_api_actions
    api_namespace.create_api_actions.each do |action|
      self.create_api_actions.build(action.attributes.merge(custom_message: action.custom_message.to_s).except("id", "created_at", "updated_at", "api_namespace_id")).save
    end
  end

  def inherit_properties_from_parent
    return unless self.properties.nil?

    self.properties = api_namespace&.properties
  end

  def inject_inherited_properties
    # you can make certain primitive properties (inherited from the parent API namespace) non renderable, in these cases we have to populate the values
    # to - do write test
    return if !api_namespace&.api_form&.properties
    api_form_properties = api_namespace.api_form.properties
    api_namespace.properties.each do |key, value|
      if api_form_properties[key]['renderable'] == '0'
        self.properties[key] =  api_namespace.properties[key]
      end
    end
  end
end
