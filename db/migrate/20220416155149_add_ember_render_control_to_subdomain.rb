class AddEmberRenderControlToSubdomain < ActiveRecord::Migration[6.1]
  def change
    change_table :subdomains do |t|
      t.boolean :ember_enabled, default: false
    end
  end
end
