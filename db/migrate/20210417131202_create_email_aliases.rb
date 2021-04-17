class CreateEmailAliases < ActiveRecord::Migration[6.1]
  def change
    create_table :email_aliases do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, index: { unique: true }

      t.timestamps
    end
  end
end
