class AddAllowAttachmentsToNonPrimitiveProperties < ActiveRecord::Migration[6.1]
  def change
    add_column :non_primitive_properties, :allow_attachments, :boolean, default: false
  end
end
