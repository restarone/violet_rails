class AddAnalyticsReportFrequencyToSubdomains < ActiveRecord::Migration[6.1]
  def change
    change_table :subdomains do |t|
      t.string :analytics_report_frequency, default: "never"
    end
  end
end
