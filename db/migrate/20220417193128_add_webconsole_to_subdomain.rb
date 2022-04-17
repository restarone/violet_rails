class AddWebconsoleToSubdomain < ActiveRecord::Migration[6.1]
  def change
    change_table :subdomains do |t|
      t.boolean :web_console_enabled, default: false
    end
  end
end
