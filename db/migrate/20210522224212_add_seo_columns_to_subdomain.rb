class AddSeoColumnsToSubdomain < ActiveRecord::Migration[6.1]
  def change
    change_table :subdomains do |t|
      t.string :description
      t.string :keywords
    end
  end
end
