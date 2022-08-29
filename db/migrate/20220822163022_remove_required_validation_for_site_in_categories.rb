class RemoveRequiredValidationForSiteInCategories < ActiveRecord::Migration[6.1]
  def up
    change_table :comfy_cms_categories do |t|
      t.change :site_id, :integer, null: true
    end
  end

  def down
    change_table :comfy_cms_categories do |t|
      t.change :site_id, :integer, null: false
    end
  end
end
