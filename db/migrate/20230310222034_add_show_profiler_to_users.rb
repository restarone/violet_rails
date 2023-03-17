class AddShowProfilerToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :show_profiler, :boolean, default: false
  end
end
