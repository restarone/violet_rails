class CreateCallToActions < ActiveRecord::Migration[6.1]
  def change
    create_table :call_to_actions do |t|
      t.string :title, null: false
      t.string :cta_type, default: 'contact'

      t.timestamps
    end
  end
end
