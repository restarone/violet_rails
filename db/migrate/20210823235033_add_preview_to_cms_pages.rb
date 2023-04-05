class AddPreviewToCmsPages < ActiveRecord::Migration[6.1]
  LIMIT = 16777215

  def change
    add_column :comfy_cms_pages, :preview_content, :text, limit: LIMIT
  end
end
