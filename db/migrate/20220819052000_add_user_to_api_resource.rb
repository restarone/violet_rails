class AddUserToApiResource < ActiveRecord::Migration[6.1]
  def change
    add_reference :api_resources, :user
  end
end
