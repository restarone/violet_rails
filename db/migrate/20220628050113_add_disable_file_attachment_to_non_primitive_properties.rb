class AddDisableFileAttachmentToNonPrimitiveProperties < ActiveRecord::Migration[6.1]
  def change
    add_column :non_primitive_properties, :disable_file_attachment, :boolean, default: false
  end
end
