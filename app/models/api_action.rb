class ApiAction < ApplicationRecord
  include Encryptable
  attr_encrypted :bearer_token

  belongs_to :api_namespace, optional: true
  belongs_to :api_resource, optional: true

  enum action_type: { send_email: 0, send_web_request: 1, redirect: 2, serve_file: 3 }

  default_scope { order(position: 'ASC') }

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
    end
  end

  def send_web_request
    begin
      response = HTTParty.post(request_url, 
                    body: evaluate_payload,
                    headers: request_headers)
      if response.success?
        self.update(lifecycle_stage: 'complete', lifecycle_message: response.to_s)
      else
        self.update(lifecycle_stage: 'failed', lifecycle_message: response.to_s)
      end
    rescue => e
      self.update(lifecycle_stage: 'failed', lifecycle_message: e.message)
    end
  end

  def redirect;end

  def serve_file;end

  def evaluate_payload
    payload_mapping
  end

  def request_headers
    { 'Content-Type' => 'application/json', 'X-AUTHORIZATION': "bearer #{bearer_token}" }
  end
end
