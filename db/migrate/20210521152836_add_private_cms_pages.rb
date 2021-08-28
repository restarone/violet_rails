class AddPrivateCmsPages < ActiveRecord::Migration[6.1]
  def change
    change_table :comfy_cms_pages do |t|
      ## makes pages private to users who are signed in + have can_view_restricted_pages: true
      t.boolean :is_restricted, default: false
    end
  end
end
