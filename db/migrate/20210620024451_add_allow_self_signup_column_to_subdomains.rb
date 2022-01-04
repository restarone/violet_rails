class AddAllowSelfSignupColumnToSubdomains < ActiveRecord::Migration[6.1]
  def change
    change_table :subdomains do |t|
      t.boolean :allow_user_self_signup, default: true
    end
  end
end
