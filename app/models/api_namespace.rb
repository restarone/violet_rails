class ApiNamespace < ApplicationRecord
  extend FriendlyId
  include JsonbFieldsParsable
  include Comfy::Cms::WithCategories

  friendly_id :name, use: :slugged

  attr_accessor :has_form

  after_save :update_api_form
  
  has_many :api_resources, dependent: :destroy
  accepts_nested_attributes_for :api_resources

  has_one :api_form, dependent: :destroy
  accepts_nested_attributes_for :api_form

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

  has_many :api_namespace_keys, dependent: :destroy
  has_many :api_keys, through: :api_namespace_keys

  ransacker :properties do |_parent|
    Arel.sql("api_namespaces.properties::text") 
  end

  REGISTERED_PLUGINS = {
    subdomain_events: {
      slug: 'subdomain_events',
      version: 1,
    }
  }

  API_ACCESSIBILITIES = {
    full_access: ['full_access'],
    full_read_access: ['full_access', 'full_read_access'],
    full_read_access_in_api_namespace: ['full_access', 'full_read_access', 'delete_access_api_namespace_only', 'allow_exports', 'allow_duplication', 'allow_social_share_metadata', 'full_access_api_namespace_only', 'read_api_resources_only', 'full_access_for_api_resources_only', 'delete_access_for_api_resources_only', 'read_api_actions_only', 'full_access_for_api_actions_only', 'read_external_api_connections_only', 'full_access_for_external_api_connections_only', 'read_api_clients_only', 'full_access_for_api_clients_only', 'full_access_for_api_form_only'],
    full_access_api_namespace_only: ['full_access', 'full_access_api_namespace_only'],
    delete_access_api_namespace_only: ['full_access', 'full_access_api_namespace_only', 'delete_access_api_namespace_only'],
    allow_exports: ['full_access', 'full_access_api_namespace_only', 'allow_exports'],
    allow_duplication: ['full_access', 'full_access_api_namespace_only', 'allow_duplication'],
    allow_social_share_metadata: ['full_access', 'full_access_api_namespace_only', 'allow_social_share_metadata'],
    read_api_resources_only: ['full_access', 'full_read_access', 'full_access_for_api_resources_only', 'read_api_resources_only', 'delete_access_for_api_resources_only'],
    full_access_for_api_resources_only: ['full_access', 'full_access_for_api_resources_only'],
    delete_access_for_api_resources_only: ['full_access', 'full_access_for_api_resources_only', 'delete_access_for_api_resources_only'],
    read_api_actions_only: ['full_access', 'full_read_access', 'full_access_for_api_actions_only', 'read_api_actions_only'],
    full_access_for_api_actions_only: ['full_access', 'full_access_for_api_actions_only'],
    read_external_api_connections_only: ['full_access', 'full_read_access', 'full_access_for_external_api_connections_only', 'read_external_api_connections_only'],
    full_access_for_external_api_connections_only: ['full_access', 'full_access_for_external_api_connections_only'],
    full_access_for_api_form_only: ['full_access', 'full_access_for_api_form_only'],
    read_api_keys_only: ['full_access', 'delete_access', 'read_access'],
    full_access_for_api_keys_only: ['full_access'],
    delete_access_for_api_keys_only: ['full_access', 'delete_access'],
  }

  scope :filter_by_user_api_accessibility, ->(user) { 
    api_accessibility = user.api_accessibility['api_namespaces']

    if api_accessibility.present? && api_accessibility.keys.include?('all_namespaces')
      self
    elsif api_accessibility.present? && api_accessibility.keys.include?('namespaces_by_category')
      category_specific_keys = api_accessibility['namespaces_by_category'].keys
      if category_specific_keys.include?('uncategorized')
        self.includes(:categories).left_outer_joins(categorizations: :category).where("comfy_cms_categories.id IS ? OR comfy_cms_categories.label IN (?)", nil, category_specific_keys)
      else
        self.includes(:categories).for_category(category_specific_keys)
      end
    else
      self.none
    end
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

        random_hex = SecureRandom.hex(4)
        new_api_namespace = self.dup
        new_api_namespace.name = self.name + '-copy-' + random_hex
        new_api_namespace.save!
    
        if duplicate_associations
          # Duplicate ApiForm
          if self.api_form.present?
            new_api_form = self.api_form.dup
            new_api_form.api_namespace = new_api_namespace
            new_api_form.save!
          end
    
          # Duplicate ApiKeys
          self.api_keys.each do |api_key|
            label = api_key.label + '-copy-' + random_hex
            new_api_key = ApiKey.create(label: label, authentication_strategy: api_key.authentication_strategy)
            ApiNamespaceKey.create(api_key_id: new_api_key.id, api_namespace_id: new_api_namespace.id )
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

  def export_as_json(include_associations: false)
    if include_associations
      self.to_json(
        root: 'api_namespace',
        include: [
          :api_form,
          :external_api_clients,
          :non_primitive_properties,
          {
            api_actions: {
              except: [:salt, :encrypted_bearer_token], # Copying salt raises error related to encoding and these are encypted data. So, we should not copy such values.
              methods: [:bearer_token, :type]
            }
          },
          {
            api_resources: {
              include: [
                {
                  api_actions: {
                    except: [:salt, :encrypted_bearer_token],
                    methods: [:bearer_token, :type]
                  }
                }
              ]
            }
          },
          {
            api_keys: {
              except: [:salt, :encrypted_token], # Copying salt raises error related to encoding and these are encypted data. So, we should not copy such values.
              methods: [:token]
            }
          }
        ]
      )
    else
      self.to_json(root: 'api_namespace')
    end
  end

  def self.import_as_json(json_str)
    begin
      ActiveRecord::Base.transaction do
        neglected_attributes = {
          api_action: ['id', 'created_at', 'updated_at', 'encrypted_bearer_token', 'salt', 'api_namespace_id', 'api_resource_id'],
          api_key: ['id', 'created_at', 'updated_at', 'api_namespace_id', 'token'],
          api_form: ['id', 'created_at', 'updated_at', 'api_namespace_id'],
          api_namespace: ['id', 'created_at', 'updated_at', 'slug'],
          api_resource: ['id', 'created_at', 'updated_at', 'api_namespace_id'],
          external_api_client: ['id', 'created_at', 'updated_at', 'slug', 'api_namespace_id'],
          non_primitive_property: ['id', 'created_at', 'updated_at', 'api_resource_id', 'api_namespace_id'],
        }

        hash = begin
                JSON.parse(json_str)['api_namespace']
              rescue JSON::ParserError => e
                json_str = json_str.gsub('=>',':').gsub('nil','null')
                JSON.parse(json_str)['api_namespace']
              end
      
        # creating api_namespace
        if ApiNamespace.find_by(slug: hash['slug']).present?
          random_hex = SecureRandom.hex(4)
          hash['name'] = hash['name'] + '-' + random_hex
        end

        api_namespace_hash = hash.except(*neglected_attributes[:api_namespace])
        # Remove keys that are not available in table since we have associations as well.
        api_namespace_attributes = ApiNamespace.new.attributes.keys
        api_namespace_hash = api_namespace_hash.reject{ |k| !api_namespace_attributes.include?(k.to_s) }

        new_api_namespace = ApiNamespace.create!(api_namespace_hash)

        # Creating api_form
        if hash['api_form'].present?
          api_form_hash = hash['api_form'].except(*neglected_attributes[:api_form]).merge({'api_namespace_id': new_api_namespace.id})
          ApiForm.create!(api_form_hash)
        end

        # Creating api_keys
        if hash['api_keys'].present? && hash['api_keys'].is_a?(Array)
          hash['api_keys'].each do |api_key_hash|
            api_key_hash = api_key_hash.except(*neglected_attributes[:api_key])
            api_key_hash['label'] = api_key_hash['label'] + '_' + random_hex if random_hex.present?
            api_key = ApiKey.create!(api_key_hash)
            ApiNamespaceKey.create(api_key_id: api_key.id, api_namespace_id: new_api_namespace.id )
          end
        end
        
        # Creating external_api_clients
        if hash['external_api_clients'].present? && hash['external_api_clients'].is_a?(Array)
          hash['external_api_clients'].each do |external_api_client_hash|
            external_api_client_hash = external_api_client_hash.except(*neglected_attributes[:external_api_client]).merge({'api_namespace_id': new_api_namespace.id})
            ExternalApiClient.create!(external_api_client_hash)
          end
        end
        
        # Creating non_primitive_properties
        if hash['non_primitive_properties'].present? && hash['non_primitive_properties'].is_a?(Array)
          hash['non_primitive_properties'].each do |non_primitive_property_hash|
            non_primitive_property_hash = non_primitive_property_hash.except(*neglected_attributes[:non_primitive_property]).merge({'api_namespace_id': new_api_namespace.id})
            NonPrimitiveProperty.create!(non_primitive_property_hash)
          end
        end
        
        # Creating api_actions
        if hash['api_actions'].present? && hash['api_actions'].is_a?(Array)
          hash['api_actions'].each do |api_action_hash|
            api_action_hash = api_action_hash.except(*neglected_attributes[:api_action]).merge({'api_namespace_id': new_api_namespace.id})
            ApiAction.create!(api_action_hash)
          end
        end
        
        # Creating api_resources & executed_api_actions
        if hash['api_resources'].present? && hash['api_resources'].is_a?(Array)
          hash['api_resources'].each do |api_resource_hash|
            current_date_time = Time.zone.now
            filtered_api_resource_hash = api_resource_hash.except(*neglected_attributes[:api_resource]).merge({'api_namespace_id': new_api_namespace.id, 'created_at': current_date_time, 'updated_at': current_date_time})
            # Remove keys that are not available in table since we have association:api_actions as well.
            api_resource_attributes = ApiResource.new.attributes.keys
            filtered_api_resource_hash = filtered_api_resource_hash.reject{ |k| !api_resource_attributes.include?(k.to_s) }
            
            # For skipping before_create callback for ApiResource
            ApiResource.insert(filtered_api_resource_hash)
            new_api_resource = new_api_namespace.reload.api_resources.last

            api_resource_hash['api_actions'].each do |api_resource_api_action_hash|
              api_resource_api_action_hash = api_resource_api_action_hash.except(*neglected_attributes[:api_action]).merge({'api_resource_id': new_api_resource.id})
              ApiAction.create!(api_resource_api_action_hash)
            end
          end
        end

        { success: true, data: new_api_namespace }
      end
    rescue => e
      { success: false, message: e.message }
    end
  end

  def snippet(with_brackets: true)
    return unless self.api_form.present?

    cms_snippet = "cms:helper render_form, #{self.api_form.id}"
    cms_snippet = "{{ #{cms_snippet} }}" if with_brackets

    cms_snippet
  end

  def cms_associations
    # We will need to refactor this query.
    # regex did not work in SQL query. /cms:helper render_api_namespace_resource(_index)? ('|")#{self.slug}('|")/
    associations = Comfy::Cms::Page
                    .joins(:fragments)
                    .where('comfy_cms_fragments.identifier': 'content')
                    .where("comfy_cms_fragments.content ~ ? AND comfy_cms_fragments.content LIKE ?", "render_api_namespace_resource(_index)?", "%#{self.slug}%")
                    .select { |page| page.fragments.where(identifier: 'content').first.content.match(/cms:helper render_api_namespace_resource(_index)? ('|")#{self.slug}('|")/)}

    associations += Comfy::Cms::Snippet.where('comfy_cms_snippets.identifier = ? OR comfy_cms_snippets.identifier = ?', self.slug, "#{self.slug}-show")

    if self.snippet.present?
      associations += Comfy::Cms::Page.joins(:fragments).where('comfy_cms_fragments.content LIKE ?', "%#{self.snippet(with_brackets: false)}%")
      associations += Comfy::Cms::Layout.where('comfy_cms_layouts.content LIKE ?', "%#{self.snippet(with_brackets: false)}%")
      associations += Comfy::Cms::Snippet.where('comfy_cms_snippets.content LIKE ?', "%#{self.snippet(with_brackets: false)}%")
    end

    associations.uniq
  end
end
