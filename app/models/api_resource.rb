class ApiResource < ApplicationRecord
  include JsonbFieldsParsable
  include JsonbSearch::Searchable

  after_initialize :inherit_properties_from_parent
  
  after_initialize do
    api_namespace.api_form.api_resource = self unless api_namespace&.api_form.nil?
  end

  belongs_to :api_namespace

  before_create :inject_inherited_properties

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

  def tracked_event
    Ahoy::Event.where(name: 'api-resource-create').where("properties @> ?", { api_resource_id: self.id }.to_json).last
  end

  def tracked_user
    User.find_by(id: tracked_event.properties.dig('user_id')) if tracked_event
  end

  def execute_model_context_api_actions(class_name)
    api_actions = self.send(class_name).where(action_type: ApiAction::EXECUTION_ORDER[:model_level], lifecycle_stage: 'initialized')

    ApiAction::EXECUTION_ORDER[:model_level].each do |action_type|
      if ApiAction.action_types[action_type] == ApiAction.action_types[:custom_action]
        begin
          custom_actions = api_actions.where(action_type: 'custom_action')
          custom_actions.each do |custom_action|
            custom_action.execute_action
          end
        rescue
          # error-actions are executed already in api-action level.
          nil
        end
      elsif [ApiAction.action_types[:send_email], ApiAction.action_types[:send_web_request]].include?(ApiAction.action_types[action_type])
        api_actions.where(action_type: ApiAction.action_types[action_type]).each do |api_action|
          api_action.execute_action
        end
      end
    end if api_actions.present?
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

  def execute_create_api_actions
    clone_api_actions('create_api_actions')
    FireApiActionsJob.perform_async(self.id, 'create_api_actions', Current.user&.id, Current.visit&.id)
  end

  def execute_update_api_actions
    clone_api_actions('update_api_actions')
    FireApiActionsJob.perform_async(self.id, 'update_api_actions', Current.user&.id, Current.visit&.id)
  end
end
