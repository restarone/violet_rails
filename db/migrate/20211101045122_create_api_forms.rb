class CreateApiForms < ActiveRecord::Migration[6.1]
  def change
    create_table :api_forms do |t|
      t.jsonb :properties
      t.references :api_namespace, null: false, foreign_key: true
      t.string :success_message
      t.string :failure_message
      t.string :submit_button_label, default: 'Submit'
      t.string :title
      t.boolean :show_recaptcha, default: false

      t.timestamps
    end
  end
end
