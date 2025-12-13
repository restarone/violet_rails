class ApiAction < ApplicationRecord
  include Encryptable
  include JsonbFieldsParsable
  include DynamicAttribute

  attr_encrypted :bearer_token
  attr_dynamic :email, :email_subject, :custom_message, :payload_mapping, :custom_headers, :request_url, :redirect_url

  after_update :update_api_resource_actions, if: Proc.new { self.api_namespace_action? }

  belongs_to :api_namespace, optional: true
  belongs_to :api_resource, optional: true

  enum action_type: { send_email: 0, send_web_request: 1, redirect: 2, serve_file: 3, custom_action: 4 }

  enum lifecycle_stage: {initialized: 0, executing: 1, complete: 2, failed: 3, discarded: 4}
  
  enum redirect_type: { cms_page: 0, dynamic_url: 1 }

  # api_namespace_action acts as class defination and api_resource_actions act as instance of api_namespace_action
  has_many :api_resource_actions, class_name: 'ApiAction', foreign_key: :parent_id

  belongs_to :api_namespace_action, class_name: 'ApiAction', foreign_key: :parent_id, optional: true

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

  def execute_action(run_error_action = true)
    self.update(lifecycle_stage: 'executing')
    send(action_type, run_error_action)
  end

  def self.execute_model_context_api_actions
    api_actions = self.where(action_type: ApiAction::EXECUTION_ORDER[:model_level], lifecycle_stage: 'initialized')
    
    ApiAction::EXECUTION_ORDER[:model_level].each do |action_type|
      if ApiAction.action_types[action_type] == ApiAction.action_types[:custom_action]
        custom_actions = api_actions.where(action_type: 'custom_action')
        custom_actions.each do |custom_action|
          FireApiActionsJob.perform_async(custom_action.id, Current.user&.id, Current.visit&.id, Current.is_api_html_renderer_request)
        end
      elsif [ApiAction.action_types[:send_email], ApiAction.action_types[:send_web_request]].include?(ApiAction.action_types[action_type])
        api_actions.where(action_type: ApiAction.action_types[action_type]).each do |api_action|
          FireApiActionsJob.perform_async(api_action.id, Current.user&.id, Current.visit&.id, Current.is_api_html_renderer_request)
        end
      end
    end if api_actions.present?
  end


  def execute_error_actions(error)
    self.update(lifecycle_stage: 'failed', lifecycle_message: error)

    return if type == 'ErrorApiAction' || api_resource.nil?

    api_resource.api_namespace.error_api_actions.each do |action|
      api_resource.error_api_actions.create(action.attributes.merge(custom_message: action.custom_message.to_s).except("id", "created_at", "updated_at", "api_namespace_id"))
    end
    api_resource.error_api_actions.each(&:execute_action)
  end

  def api_namespace_action?
    api_namespace_id.present?
  end

  def api_resource_action?
    api_resource_id.present?
  end

  private

  def update_api_resource_actions
    api_actions_to_update = self.api_resource_actions.where.not(lifecycle_stage: [:complete, :discarded])
    api_actions_to_update.update_all({
      payload_mapping: payload_mapping,
      include_api_resource_data: include_api_resource_data,
      redirect_url: redirect_url,
      request_url: request_url,
      position: position,
      email: email,
      file_snippet: file_snippet,
      custom_headers: custom_headers,
      http_method: http_method,
      method_definition: method_definition,
      email_subject: email_subject,
      redirect_type: redirect_type,
    })
    ActionText::RichText.where(record_type: 'ApiAction', record_id: api_actions_to_update.pluck(:id)).update_all(body: custom_message.to_s)
  end

  def send_email(run_error_action = true)
    begin
      ApiActionMailer.send_email(self).deliver_now
      self.update(lifecycle_stage: 'complete', lifecycle_message: email)
    rescue Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPServerBusy => e
      execute_error_actions("SMTP Error: #{e.message}") if run_error_action
      raise
    rescue StandardError => e
      execute_error_actions(e.message) if run_error_action
      raise
    end
  end

  def send_web_request(run_error_action = true)
    begin
      response = HTTParty.send(http_method.to_s, request_url_evaluated, 
                    { body: payload_mapping_evaluated, headers: request_headers })
      if response.success?
        self.update(lifecycle_stage: 'complete', lifecycle_message: response.to_s)
      else
        execute_error_actions(response.to_s)
      end 
    rescue HTTParty::Error, SocketError => e
      execute_error_actions("HTTP Error: #{e.message}") if run_error_action 
      raise
    rescue StandardError => e
      execute_error_actions(e.message) if run_error_action
      raise
    end
  end

  def custom_action(run_error_action = true)
    begin
      custom_api_action = CustomApiAction.new
      eval("def custom_api_action.run_custom_action(api_action: , api_namespace: , api_resource: , current_visit: , current_user: nil); #{self.method_definition}; end")

      response = custom_api_action.run_custom_action(api_action: self, api_namespace: self.api_resource&.api_namespace, api_resource: self.api_resource, current_visit: Current.visit, current_user: Current.user)

      self.update(lifecycle_stage: 'complete', lifecycle_message: response.to_json)
    rescue NameError, NoMethodError => e
      execute_error_actions("Custom Action Error: #{e.message}") if run_error_action
      raise
    rescue StandardError => e
      execute_error_actions(e.message) if run_error_action
      raise
    end
  end

  def redirect(run_error_action = true);end

  def serve_file(run_error_action = true);end

  def request_headers
    headers = custom_headers_evaluated.gsub('SECRET_BEARER_TOKEN', bearer_token.to_s)
    { 'Content-Type' => 'application/json' }.merge(JSON.parse(headers))
  end
end
