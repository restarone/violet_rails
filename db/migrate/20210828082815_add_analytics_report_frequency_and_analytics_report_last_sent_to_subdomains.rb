class AddAnalyticsReportFrequencyAndAnalyticsReportLastSentToSubdomains < ActiveRecord::Migration[6.1]
  def change
    change_table :subdomains do |t|
      t.string :analytics_report_frequency, default: "never"
      t.datetime :analytics_report_last_sent
    end
  end
end
