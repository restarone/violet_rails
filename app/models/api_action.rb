class ApiAction < ApplicationRecord
  belongs_to :api_namespace, optional: true
  belongs_to :api_resource, optional: true

  enum trigger: { new_event: 0, create_event: 1, update_event: 2, destroy_event: 3, show_event: 4, error_event: 5 }

  enum action_type: { send_email: 0, send_web_request: 1, redirect: 2, serve_file: 3 }

  def execute_action
    send(action_type)
  end

  private

  def send_email
    ApiActionMailer.send_email(self).deliver_now
  end

  def send_web_request
    response = HTTParty.post(request_url, 
                  body: evaluate_payload,
                  headers: request_headers)
  end

  def redirect
    
  end

  def serve_file

  end

  def evaluate_payload
    payload_mapping
  end

  def request_headers
    { 'Content-Type' => 'application/json', 'X-AUTHORIZATION': bearer_token }
  end
end
