class AddForumAndBlogControlsToSubdomains < ActiveRecord::Migration[6.1]
  change_table :subdomains do |t|
    t.boolean :forum_enabled, default: true
    t.boolean :blog_enabled, default: true
  end
end
