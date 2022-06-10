class AddEmailSubjectToApiActions < ActiveRecord::Migration[6.1]
  def change
    add_column :api_actions, :email_subject, :text
  end
end
