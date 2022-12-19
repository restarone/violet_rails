class Current < ActiveSupport::CurrentAttributes
  attribute :user
  attribute :visit
  attribute :is_api_html_renderer_request
end