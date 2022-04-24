class AddCronSupportToExternalApiClient < ActiveRecord::Migration[6.1]
  def change
    change_table :external_api_clients do |t|
      t.string :drive_every, default: nil
    end
  end
end
