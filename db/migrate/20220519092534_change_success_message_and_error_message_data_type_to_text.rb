class ChangeSuccessMessageAndErrorMessageDataTypeToText < ActiveRecord::Migration[6.1]
  def self.up
    change_table :api_forms do |t|
      t.change :success_message, :text
      t.change :failure_message, :text
    end
  end

  def self.down
    change_table :api_forms do |t|
      t.change :success_message, :string
      t.change :failure_message, :string
    end
  end
end
