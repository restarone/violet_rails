class AddSessionTimeoutToUsers < ActiveRecord::Migration[6.1]
  def change
    change_table :users do |t|
      t.string :session_timeoutable_in, default: User::SESSION_TIMEOUT[0][:slug]
    end
  end
end
