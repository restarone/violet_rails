class CreateNonPrimitiveProperties < ActiveRecord::Migration[6.1]
  def change
    create_table :non_primitive_properties do |t|
      t.string :label
      t.integer :field_type, default: 0
      t.references :api_resource, foreign_key: true
      t.references :api_namespace, foreign_key: true

      t.timestamps
    end
  end
end
