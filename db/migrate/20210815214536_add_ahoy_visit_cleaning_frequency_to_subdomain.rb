class AddAhoyVisitCleaningFrequencyToSubdomain < ActiveRecord::Migration[6.1]
  def change
    change_table :subdomains do |t|
      t.string :purge_visits_every, default: "3.months"
    end
  end
end
