class ApiNamespace < ApplicationRecord
  extend FriendlyId
  include JsonbFieldsParsable
  friendly_id :name, use: :slugged

  attr_accessor :has_form

  after_save :update_api_form
  
  has_many :api_resources, dependent: :destroy
  accepts_nested_attributes_for :api_resources

  has_one :api_form, dependent: :destroy
  accepts_nested_attributes_for :api_form

  has_many :api_clients, dependent: :destroy
  accepts_nested_attributes_for :api_clients

  has_many :external_api_clients, dependent: :destroy

  has_many :non_primitive_properties, dependent: :destroy
  accepts_nested_attributes_for :non_primitive_properties, allow_destroy: true
 
  has_many :api_actions, dependent: :destroy

  has_many :executed_api_actions, through: :api_resources, class_name: 'ApiAction', source: :api_actions

  has_many :new_api_actions, dependent: :destroy
  accepts_nested_attributes_for :new_api_actions, allow_destroy: true

  has_many :create_api_actions, dependent: :destroy
  accepts_nested_attributes_for :create_api_actions, allow_destroy: true

  has_many :show_api_actions, dependent: :destroy
  accepts_nested_attributes_for :show_api_actions, allow_destroy: true

  has_many :update_api_actions, dependent: :destroy
  accepts_nested_attributes_for :update_api_actions, allow_destroy: true

  has_many :destroy_api_actions, dependent: :destroy
  accepts_nested_attributes_for :destroy_api_actions, allow_destroy: true

  has_many :error_api_actions, dependent: :destroy
  accepts_nested_attributes_for :error_api_actions, allow_destroy: true

  REGISTERED_PLUGINS = {
    subdomain_events: {
      slug: 'subdomain_events',
      version: 1,
    }
  }

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
    properties.each do |key, value|
      form_hash[key] = form_properties[key].present? ? form_properties[key] : { label: key.humanize, placeholder: '', required: false, type_validation:  (ApiForm::INPUT_TYPE_MAPPING[:tel] if  value.class.to_s == 'Integer')  }
    end
    non_primitive_properties.each do |prop|
      form_hash[prop.label] = form_properties[prop.label].present? ? form_properties[prop.label] : { label: prop.label.humanize, required: false, prepopulate: '0' }
    end
    form_hash
  end

  def redirect_actions(trigger)
    api_actions.where(action_type: 'redirect', trigger: trigger)
  end

  def rerun_api_actions
    executed_api_actions.where(lifecycle_stage: 'failed').each(&:execute_action)
  end

  def discard_failed_actions
    executed_api_actions.where(lifecycle_stage: 'failed').update_all(lifecycle_stage: 'discarded')
  end

  def duplicate_api_namespace(duplicate_associations: false)
    begin
      ActiveRecord::Base.transaction do
        raise 'You cannot duplicate the api_namespace without associations if it has api_form' if duplicate_associations == false && self.api_form.present?

        new_api_namespace = self.dup
        new_api_namespace.name = self.name + '-copy-' + SecureRandom.hex(4)
        new_api_namespace.save!
    
        if duplicate_associations
          # Duplicate ApiForm
          if self.api_form.present?
            new_api_form = self.api_form.dup
            new_api_form.api_namespace = new_api_namespace
            new_api_form.save!
          end
    
          # Duplicate ApiClients
          self.api_clients.each do |api_client|
            new_api_client = api_client.dup
            new_api_client.api_namespace = new_api_namespace
            new_api_client.save!
          end
    
          # Duplicate ExternalApiClients
          self.external_api_clients.each do |external_api_client|
            new_external_api_client = external_api_client.dup
            new_external_api_client.api_namespace = new_api_namespace
            new_external_api_client.save!
          end
    
          # Duplicate NonPrimitiveProperties
          self.non_primitive_properties.each do |non_primitive_property|
            new_non_primitive_property = non_primitive_property.dup
            new_non_primitive_property.api_namespace = new_api_namespace
            new_non_primitive_property.save!
          end
    
          # Duplicate ApiActions
          self.api_actions.each do |api_action|
            new_api_action = api_action.dup
            new_api_action.api_namespace = new_api_namespace
            new_api_action.save!
          end
    
          # Duplicate ApiResources & ExecutedApiActions
          self.api_resources.each do |api_resource|
            # For skipping before_create callback for ApiResource
            current_date_time = Time.zone.now
            ApiResource.insert(api_resource.attributes.except("id", "created_at", "updated_at", 'api_namespace_id').merge({api_namespace_id: new_api_namespace.id, created_at: Time.zone.now, updated_at: Time.zone.now}))
            new_api_resource = new_api_namespace.reload.api_resources.last
    
            api_resource.api_actions.each do |executed_api_action|
              new_executed_api_action = executed_api_action.dup
              new_executed_api_action.api_resource = new_api_resource
              new_executed_api_action.save!
            end
          end
        end

        { success: true, data: new_api_namespace }
      end
    rescue => e
      { success: false, message: e.message }
    end
  end
end
