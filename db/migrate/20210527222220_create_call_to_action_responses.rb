class CreateCallToActionResponses < ActiveRecord::Migration[6.1]
  def change
    create_table :call_to_action_responses do |t|
      t.references :call_to_action, null: false, foreign_key: true
      t.jsonb :properties

      t.timestamps
    end
  end
end
