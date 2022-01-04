class AddAuthenticatedForumColumnToSubdomain < ActiveRecord::Migration[6.1]
  def change
    change_table :subdomains do |t|
      t.boolean :forum_is_private, default: false
    end
  end
end
