class CreateMeetings < ActiveRecord::Migration[6.1]
  def change
    create_table :meetings do |t|
      t.string :name
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.text :participant_emails, array: true, default: []
      t.text :description
      t.string :timezone, null: false
      t.string :location
      t.string :status, null: false
      t.string :external_meeting_id, null: false
      t.jsonb :custom_properties, default: '{}'

      t.timestamps
    end
    add_index :meetings, :external_meeting_id, unique: true
  end
end
