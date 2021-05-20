class AddAdditionalConfigurationToSubdomain < ActiveRecord::Migration[6.1]
  def change
    change_table :subdomains do |t|
      t.string :html_title
      t.string :blog_title
      t.string :blog_html_title
      t.string :forum_title
      t.string :forum_html_title
    end
  end
end
