class CreateSubdomainRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :subdomain_requests do |t|
      t.string :subdomain_name
      t.string :email
      t.boolean :approved, default: false
      t.boolean :requires_web, default: true
      t.boolean :requires_blog, default: true
      t.boolean :requires_forum, default: true
      t.datetime :deleted_at
      t.timestamps
    end
    add_index :subdomain_requests, :deleted_at
    add_index :subdomain_requests, :subdomain_name
    add_index :subdomain_requests, :email
  end
end
