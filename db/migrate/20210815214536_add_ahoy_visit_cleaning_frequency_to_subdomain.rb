class AddAhoyVisitCleaningFrequencyToSubdomain < ActiveRecord::Migration[6.1]
  def change
    change_table :subdomains do |t|
      t.string :purge_visits_every, default: "never"
    end
  end
end
