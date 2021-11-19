class AddHttpMethodToApiActions < ActiveRecord::Migration[6.1]
  def change
    change_table :api_actions do |t|
      t.string :http_method
    end
  end
end
