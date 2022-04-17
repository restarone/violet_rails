class AddGraphqlToSubdomain < ActiveRecord::Migration[6.1]
  def change
    change_table :subdomains do |t|
      t.boolean :graphql_enabled, default: false
    end
  end
end
