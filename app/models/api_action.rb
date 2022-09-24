class ApiAction < ApplicationRecord
  include Encryptable
  include JsonbFieldsParsable
  include DynamicAttribute

  attr_encrypted :bearer_token
  attr_dynamic :email, :email_subject, :custom_message, :payload_mapping, :custom_headers, :request_url, :redirect_url

  after_update :update_executed_actions_payload, if: Proc.new { api_namespace.present? && saved_change_to_payload_mapping? }

  belongs_to :api_namespace, optional: true
  belongs_to :api_resource, optional: true

  enum action_type: { send_email: 0, send_web_request: 1, redirect: 2, serve_file: 3, custom_action: 4 }

  enum lifecycle_stage: {initialized: 0, executing: 1, complete: 2, failed: 3, discarded: 4}
  
  enum redirect_type: { cms_page: 0, dynamic_url: 1 }

  EXECUTION_ORDER = {
    model_level: ['send_email', 'send_web_request', 'custom_action'],
    controller_level: ['serve_file', 'redirect'],
  }

  HTTP_METHODS = ['get', 'post', 'patch', 'put', 'delete']

  default_scope { order(position: 'ASC') }

  ransacker :action_type, formatter: proc {|v| action_types[v]}

  has_rich_text :custom_message

  validates :http_method, inclusion: { in: ApiAction::HTTP_METHODS}, allow_blank: true

  validates :method_definition, safe_executable: true

  def self.children
    ['new_api_actions', 'create_api_actions', 'show_api_actions', 'update_api_actions', 'destroy_api_actions', 'error_api_actions']
  end

  def execute_action
    self.update(lifecycle_stage: 'executing')
    send(action_type)
  end

  def self.execute_model_context_api_actions
    api_actions = self.where(action_type: ApiAction::EXECUTION_ORDER[:model_level], lifecycle_stage: 'initialized')
    
    ApiAction::EXECUTION_ORDER[:model_level].each do |action_type|
      if ApiAction.action_types[action_type] == ApiAction.action_types[:custom_action]
        custom_actions = api_actions.where(action_type: 'custom_action')
        custom_actions.each do |custom_action|
          FireApiActionsJob.perform_async(custom_action.id, Current.user&.id, Current.visit&.id)
        end
      elsif [ApiAction.action_types[:send_email], ApiAction.action_types[:send_web_request]].include?(ApiAction.action_types[action_type])
        api_actions.where(action_type: ApiAction.action_types[action_type]).each do |api_action|
          FireApiActionsJob.perform_async(api_action.id, Current.user&.id, Current.visit&.id)
        end
      end
    end if api_actions.present?
  end

  private

  def update_executed_actions_payload
    ApiAction.where(api_resource_id: api_namespace.api_resources.pluck(:id), payload_mapping: payload_mapping_previously_was, type: type, action_type: action_type).update_all(payload_mapping: payload_mapping)
  end

  def send_email
    begin
      ApiActionMailer.send_email(self).deliver_now
      self.update(lifecycle_stage: 'complete', lifecycle_message: email)
    rescue Exception => e
      self.update(lifecycle_stage: 'failed', lifecycle_message: e.message)
      execute_error_actions
      raise
    end
  end

  def send_web_request
    begin
      response = HTTParty.send(http_method.to_s, request_url_evaluated, 
                    { body: payload_mapping_evaluated, headers: request_headers })
      if response.success?
        self.update(lifecycle_stage: 'complete', lifecycle_message: response.to_s)
      else
        self.update(lifecycle_stage: 'failed', lifecycle_message: response.to_s)
        execute_error_actions
      end 
    rescue => e
      self.update(lifecycle_stage: 'failed', lifecycle_message: e.message)
      execute_error_actions
      raise
    end
  end

  def custom_action
    begin
      custom_api_action = CustomApiAction.new
      eval("def custom_api_action.run_custom_action(api_action: , api_namespace: , api_resource: , current_visit: , current_user: nil); #{self.method_definition}; end")

      response = custom_api_action.run_custom_action(api_action: self, api_namespace: self.api_resource&.api_namespace, api_resource: self.api_resource, current_visit: Current.visit, current_user: Current.user)

      self.update(lifecycle_stage: 'complete', lifecycle_message: response.to_json)
    rescue => e
      self.update(lifecycle_stage: 'failed', lifecycle_message: e.message)
      execute_error_actions
      raise
    end
  end

  def redirect;end

  def serve_file;end

  def request_headers
    headers = custom_headers_evaluated.gsub('SECRET_BEARER_TOKEN', bearer_token.to_s)
    { 'Content-Type' => 'application/json' }.merge(JSON.parse(headers))
  end

  def execute_error_actions
    return if type == 'ErrorApiAction' || api_resource.nil?

    api_resource.api_namespace.error_api_actions.each do |action|
      api_resource.error_api_actions.create(action.attributes.merge(custom_message: action.custom_message.to_s).except("id", "created_at", "updated_at", "api_namespace_id"))
    end
    api_resource.error_api_actions.each(&:execute_action)
  end
end
