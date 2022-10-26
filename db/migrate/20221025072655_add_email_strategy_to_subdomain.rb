class AddEmailStrategyToSubdomain < ActiveRecord::Migration[6.1]
  def change
    add_column :subdomains, :email_strategy, :boolean, default: false
  end
end
