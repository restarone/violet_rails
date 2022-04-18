class AddAuthenticationToEmber < ActiveRecord::Migration[6.1]
  def change
    change_table :subdomains do |t|
      t.boolean :ember_app_requires_authentication, default: true
    end
  end
end
