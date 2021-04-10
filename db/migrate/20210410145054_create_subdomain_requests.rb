class CreateSubdomainRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :subdomain_requests do |t|
      t.string :subdomain_name, null: false
      t.string :email, null: false
      t.boolean :approved, default: false
      t.boolean :requires_web, default: true
      t.boolean :requires_blog, default: true
      t.boolean :requires_forum, default: true

      t.timestamps
    end
  end
end
