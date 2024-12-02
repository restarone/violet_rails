# This migration comes from comfortable_mexican_sofa_engine (originally 20210404223643)
# This migration comes from active_storage (originally 20191206030411)
class CreateActiveStorageVariantRecords < ActiveRecord::Migration[6.0]
  def change
     p "already done in: db/migrate/20210403190746_create_active_storage_tables.active_storage.rb"
    
    # create_table :active_storage_variant_records do |t|
    #   t.belongs_to :blob, null: false, index: false
    #   t.string :variation_digest, null: false

    #   t.index %i[ blob_id variation_digest ], name: "index_active_storage_variant_records_uniqueness", unique: true
    #   t.foreign_key :active_storage_blobs, column: :blob_id
    # end
  end
end
