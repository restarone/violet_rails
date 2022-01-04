class AddDeliverAnalyticsReportToUsers < ActiveRecord::Migration[6.1]
  def change
    change_table :users do |t|
      t.boolean :deliver_analytics_report, default: false
    end
  end
end
