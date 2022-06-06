class AddLastRunToExternalApiClient < ActiveRecord::Migration[6.1]
  def change
    change_table :external_api_clients do |t|
      t.datetime :last_run_at
    end
  end
end
