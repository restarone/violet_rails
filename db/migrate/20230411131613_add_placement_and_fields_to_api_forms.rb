class AddPlacementAndFieldsToApiForms < ActiveRecord::Migration[6.1]
  def change
    add_column :api_forms, :placement, :string, default: 'visitor'
    safety_assured { add_column :api_forms, :fields, :json}

    ApiForm.where(fields: nil).update_all("fields = properties")
  end
end
