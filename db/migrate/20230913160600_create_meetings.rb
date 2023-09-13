class CreateMeetings < ActiveRecord::Migration[6.1]
  def change
    create_table :meetings do |t|
      t.string :name
      t.datetime :start_time
      t.datetime :end_time
      t.text :participant_emails, array: true, default: []
      t.text :description
      t.string :timezone
      t.string :location
      t.string :status
      t.string :external_meeting_id
      t.jsonb :custom_properties, default: '{}'

      t.timestamps
    end
    add_index :meetings, :external_meeting_id, unique: true
  end
end
