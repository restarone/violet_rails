json.extract! message, :id, :title, :created_at, :updated_at
json.url message_url(message, format: :json)
