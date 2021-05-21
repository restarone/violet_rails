class AddPermissionToViewRestrictedPages < ActiveRecord::Migration[6.1]
  def change
    change_table :users do |t|
      # ability to view restricted pages in db/migrate/20210521152836_add_private_cms_pages.rb
      t.boolean :can_view_restricted_pages
    end
  end
end
