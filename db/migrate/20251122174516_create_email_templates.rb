class CreateEmailTemplates < ActiveRecord::Migration[6.1]
  def change
    create_table :email_templates do |t|
      t.text :html
      t.text :template
      t.string :name
      t.string :slug

      t.timestamps
    end
  end
end
