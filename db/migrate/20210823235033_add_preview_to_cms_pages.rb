class AddPreviewToCmsPages < ActiveRecord::Migration[6.1]
  LIMIT = 16777215
  change_table :comfy_cms_pages do |t|
    t.text :preview_content, limit: LIMIT
  end
end
