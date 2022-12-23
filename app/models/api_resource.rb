class ApiResource < ApplicationRecord
  include JsonbFieldsParsable
  include JsonbSearch::Searchable
  include JsonbSearch::Sortable

  after_initialize :inherit_properties_from_parent
  
  after_initialize do
    api_namespace.api_form.api_resource = self unless api_namespace&.api_form.nil?
  end

  # Need to convert and then parse again in order to preserve keys as strings
  scope :jsonb_order_pre, -> (query_obj) { jsonb_order(JSON.parse(query_obj.to_json)) }

  belongs_to :user, optional: true

  belongs_to :api_namespace

  before_create :inject_inherited_properties, :set_creator

  after_commit :execute_create_api_actions, on: :create
  after_commit :execute_update_api_actions, on: :update

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

  def clone_api_actions(action_name)
    api_namespace.send(action_name).each do |action|
      self.send(action_name).create(action.attributes.merge('custom_message' => action.custom_message.to_s, 'lifecycle_stage' => 'initialized').except("id", "created_at", "updated_at", "api_namespace_id"))
    end
  end

  # access both primitive and non-primitive properties as hash
  def props
    non_primitive_properties = self.non_primitive_properties.map { |prop| [prop.label, prop] }.to_h
    properties.merge(non_primitive_properties)
  end

  def presence_of_required_properties
    return unless api_namespace.api_form && properties&.is_a?(Enumerable)

    properties.each do |key, value|
      if api_namespace.api_form.properties.dig(key,"required") == '1' && !value.present?
        errors.add(:properties, "#{key} is required")
      end
    end
  end

  def tracked_event
    Ahoy::Event.where(name: 'api-resource-create').where("properties @> ?", { api_resource_id: self.id }.to_json).last
  end

  def tracked_user
    User.find_by(id: tracked_event.properties.dig('user_id')) if tracked_event
  end

  def execute_model_context_api_actions(class_name)
    self.send(class_name).execute_model_context_api_actions
  end

  private

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

  def set_creator
    self.user_id = Current.user&.id
  end

  def execute_create_api_actions
    clone_api_actions('create_api_actions')
    CreateApiAction.where(id: self.create_api_actions.pluck(:id)).execute_model_context_api_actions
  end

  def execute_update_api_actions
    clone_api_actions('update_api_actions')
    UpdateApiAction.where(id: self.update_api_actions.pluck(:id)).execute_model_context_api_actions
  end
end
