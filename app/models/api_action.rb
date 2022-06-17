class ApiAction < ApplicationRecord
  include Encryptable
  include JsonbFieldsParsable
  attr_encrypted :bearer_token

  belongs_to :api_namespace, optional: true
  belongs_to :api_resource, optional: true

  enum action_type: { send_email: 0, send_web_request: 1, redirect: 2, serve_file: 3 }

  enum lifecycle_stage: {initialized: 0, executing: 1, complete: 2, failed: 3, discarded: 4}

  HTTP_METHODS = ['get', 'post', 'patch', 'put', 'delete']
  
  default_scope { order(position: 'ASC') }

  ransacker :action_type, formatter: proc {|v| action_types[v]}

  has_rich_text :custom_message

  validates :http_method, inclusion: { in: ApiAction::HTTP_METHODS}, allow_blank: true
  
  validates :payload_mapping, safe_executable: true
  validates :custom_headers, safe_executable: true

  def self.children
    ['new_api_actions', 'create_api_actions', 'show_api_actions', 'update_api_actions', 'destroy_api_actions', 'error_api_actions']
  end

  def execute_action
    self.update(lifecycle_stage: 'executing')
    send(action_type)
  end

  private

  def send_email
    begin
      ApiActionMailer.send_email(self).deliver_now
      self.update(lifecycle_stage: 'complete', lifecycle_message: email)
    rescue => e
      self.update(lifecycle_stage: 'failed', lifecycle_message: e.message)
      execute_error_actions
    end
  end

  def send_web_request
    begin
      # Fetch current_user & current_visit
      current_user = Current.user
      current_visit = Current.visit

      response = HTTParty.send(http_method.to_s, request_url, 
                    { body: evaluate_payload(current_user, current_visit), headers: evaluate_request_headers(current_user, current_visit) })

      if response.success?
        self.update(lifecycle_stage: 'complete', lifecycle_message: response.to_s)
      else
        self.update(lifecycle_stage: 'failed', lifecycle_message: response.to_s)
        execute_error_actions
      end 
    rescue => e
      self.update(lifecycle_stage: 'failed', lifecycle_message: e.message)
      execute_error_actions
    end
  end

  def redirect;end

  def serve_file;end

  def evaluate_payload(current_user, current_visit)
    payload = payload_mapping.to_json.gsub('self.', 'self.api_resource.properties_object.')
    eval(payload).to_json
  end

  def evaluate_request_headers(current_user, current_visit)
    headers = custom_headers.to_json.gsub('SECRET_BEARER_TOKEN', bearer_token)
    headers = eval(headers).to_json
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
