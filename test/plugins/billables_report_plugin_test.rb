require "test_helper"

class BillablesReportPluginTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})
    @billables_report_plugin = external_api_clients(:billables_report_plugin)
  end

  test 'sends report of total hours logged for a day, week and month' do
    mock_data

    sign_in(@user)
    perform_enqueued_jobs do
      assert_difference "EMailer.deliveries.size", +(@billables_report_plugin.metadata['REPORTING_EMAILS'].size) do          
        get start_api_namespace_external_api_client_path(api_namespace_id: @billables_report_plugin.api_namespace.id, id: @billables_report_plugin.id)
        Sidekiq::Worker.drain_all
      end
    end

    logs_for_today = [@today_log_1, @today_log_2, @today_log_3].sort_by { |log| log.created_at }
    logs_for_week = [@week_log_1, @week_log_2, @today_log_1, @today_log_2, @today_log_3, @out_of_scope_for_today].sort_by { |log| log.created_at }
    logs_for_month = [@month_log_1, @month_log_2, @week_log_1, @week_log_2, @today_log_1, @today_log_2, @today_log_3, @out_of_scope_for_today, @out_of_scope_for_week].sort_by { |log| log.created_at }

    report_email = EMailer.deliveries.last

    assert_equal 3, report_email.attachments.size

    # CSV report for the billables hour of today
    attached_report_for_today = report_email.attachments.find { |attachment| attachment.filename.match('total_hours_billed_for_day') }
    parsed_csv_report_for_today = CSV.parse(attached_report_for_today.body.raw_source.gsub(/\r\n/, "$"), col_sep: ",", row_sep: "$")

    assert_equal logs_for_today.map { |log| log.properties['how_much_time_in_hours_spent'].to_f }.sum, parsed_csv_report_for_today[0][2].to_f
    logs_for_today.each_with_index do |log, index|
      row = 3 + index
      assert_equal log.created_at.to_s, parsed_csv_report_for_today[row][0]
      assert_equal log.properties['how_much_time_in_hours_spent'], parsed_csv_report_for_today[row][1].to_f
      assert_equal log.properties['email_address'] || log.user&.email, parsed_csv_report_for_today[row][2]
      assert_equal log.properties['for_what_client'], parsed_csv_report_for_today[row][3]
      assert_equal log.properties['what_task_did_you_work_on'], parsed_csv_report_for_today[row][4]
      assert_equal log.properties['notes'], parsed_csv_report_for_today[row][5]
    end

    # CSV report for the billables hour for week
    attached_report_for_week = report_email.attachments.find { |attachment| attachment.filename.match('total_hours_billed_for_week') }
    parsed_csv_report_for_week = CSV.parse(attached_report_for_week.body.raw_source.gsub(/\r\n/, "$"), col_sep: ",", row_sep: "$")

    assert_equal logs_for_week.map { |log| log.properties['how_much_time_in_hours_spent'].to_f }.sum, parsed_csv_report_for_week[0][2].to_f
    logs_for_week.each_with_index do |log, index|
      row = 3 + index
      assert_equal log.created_at.to_s, parsed_csv_report_for_week[row][0]
      assert_equal log.properties['how_much_time_in_hours_spent'], parsed_csv_report_for_week[row][1].to_f
      assert_equal log.properties['email_address'] || log.user&.email, parsed_csv_report_for_week[row][2]
      assert_equal log.properties['for_what_client'], parsed_csv_report_for_week[row][3]
      assert_equal log.properties['what_task_did_you_work_on'], parsed_csv_report_for_week[row][4]
      assert_equal log.properties['notes'], parsed_csv_report_for_week[row][5]
    end

    # CSV report for the billables hour for month
    attached_report_for_month = report_email.attachments.find { |attachment| attachment.filename.match('total_hours_billed_for_month') }
    parsed_csv_report_for_month = CSV.parse(attached_report_for_month.body.raw_source.gsub(/\r\n/, "$"), col_sep: ",", row_sep: "$")

    assert_equal logs_for_month.map { |log| log.properties['how_much_time_in_hours_spent'].to_f }.sum, parsed_csv_report_for_month[0][2].to_f
    logs_for_month.each_with_index do |log, index|
      row = 3 + index
      assert_equal log.created_at.to_s, parsed_csv_report_for_month[row][0]
      assert_equal log.properties['how_much_time_in_hours_spent'], parsed_csv_report_for_month[row][1].to_f
      assert_equal log.properties['email_address'] || log.user&.email, parsed_csv_report_for_month[row][2]
      assert_equal log.properties['for_what_client'], parsed_csv_report_for_month[row][3]
      assert_equal log.properties['what_task_did_you_work_on'], parsed_csv_report_for_month[row][4]
      assert_equal log.properties['notes'], parsed_csv_report_for_month[row][5]
    end
  end

  test 'raises error if REPORTING_EMAILS metadata is missing or empty' do
    mock_data

    # When REPORTING_EMAILS metadata is missing
    @billables_report_plugin.update(metadata: {})

    sign_in(@user)
    perform_enqueued_jobs do
      assert_no_difference 'EMailer.deliveries.size' do          
        get start_api_namespace_external_api_client_path(api_namespace_id: @billables_report_plugin.api_namespace.id, id: @billables_report_plugin.id)
        Sidekiq::Worker.drain_all
      end
    end

    assert_equal 'REPORTING_EMAILS are missing!', @billables_report_plugin.reload.error_message

    # When REPORTING_EMAILS metadata is empty array
    @billables_report_plugin.update(metadata: {'REPORTING_EMAILS': []})

    sign_in(@user)
    perform_enqueued_jobs do
      assert_no_difference 'EMailer.deliveries.size' do          
        get start_api_namespace_external_api_client_path(api_namespace_id: @billables_report_plugin.api_namespace.id, id: @billables_report_plugin.id)
        Sidekiq::Worker.drain_all
      end
    end

    assert_equal 'REPORTING_EMAILS are missing!', @billables_report_plugin.reload.error_message
  end

  private
  def mock_data
    # logs of today
    @today_log_1 = api_resources(:tracker_entry_one)
    @today_log_2 = api_resources(:tracker_entry_three)
    @today_log_2.update(created_at: @today_log_2.created_at - 3.minutes)
    @today_log_3 = @billables_report_plugin.api_namespace.api_resources.create(@today_log_1.as_json.except('id').merge('created_at': Time.zone.now - (24.hours - 5.minutes)))

    # logs for week
    start_of_week_time = Time.zone.now.beginning_of_week.beginning_of_day
    @week_log_1 = @billables_report_plugin.api_namespace.api_resources.create(@today_log_2.as_json.except('id').merge('created_at': start_of_week_time))
    @week_log_2 = @billables_report_plugin.api_namespace.api_resources.create(@today_log_3.as_json.except('id').merge('created_at': start_of_week_time + 2.minutes))

    # logs for month
    start_of_month_time = Time.zone.now.beginning_of_month.beginning_of_day
    @month_log_1 = @billables_report_plugin.api_namespace.api_resources.create(@today_log_2.as_json.except('id').merge('created_at': start_of_month_time))
    @month_log_2 = @billables_report_plugin.api_namespace.api_resources.create(@today_log_3.as_json.except('id').merge('created_at': start_of_month_time + 2.minutes))

    @out_of_scope_for_today = @billables_report_plugin.api_namespace.api_resources.create(@today_log_1.as_json.except('id').merge('created_at': Time.zone.now - (24.hours + 1.minute)))
    @out_of_scope_for_week = @billables_report_plugin.api_namespace.api_resources.create(@today_log_2.as_json.except('id').merge('created_at': start_of_week_time - 1.minute))
    @out_of_scope_for_month = @billables_report_plugin.api_namespace.api_resources.create(@today_log_3.as_json.except('id').merge('created_at': start_of_month_time - 1.minute))
  end

  def csv_data_index(csv_content, data)
    x = nil
    y = nil

    x = csv_content.index(
      csv_content.find { |row|  y = row.index(data) }
    )

    [x, y]
  end
end
