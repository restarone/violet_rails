class AddAllowExternalAnalyticsQueryToSubdomain < ActiveRecord::Migration[6.1]
  def change
    change_table :subdomains do |t|
      t.boolean :allow_external_analytics_query, default: false
    end
  end
end
