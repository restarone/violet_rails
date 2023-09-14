json.extract! meeting, :id, :name, :start_time, :end_time, :participant_emails, :description, :timezone, :location, :status, :external_meeting_id, :created_at, :updated_at
json.url meeting_url(meeting, format: :json)
