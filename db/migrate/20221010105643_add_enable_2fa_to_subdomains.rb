class AddEnable2faToSubdomains < ActiveRecord::Migration[6.1]
  def change
    add_column :subdomains, :enable_2fa, :boolean, default: false
  end
end
