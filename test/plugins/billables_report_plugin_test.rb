require "test_helper"

class BillablesReportPluginTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(api_accessibility: {api_namespaces: {all_namespaces: {full_access: 'true'}}})

    @billables_report_plugin = external_api_clients(:billables_report_plugin)
    @tracker = api_namespaces(:time_tracker)
    @clients = @tracker.properties['for_what_client']
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

    report_email = EMailer.deliveries.last

    # Each client has 3 reports: today, week and month
    assert_equal 3 * @clients.size, report_email.attachments.size

    # Initializing client independent total-hours
    total_hours_billed_for_day = 0
    total_hours_billed_for_week = 0
    total_hours_billed_for_month = 0

    @clients.each do |client_name|
      # CSV report for the billables hour of today
      attached_report_for_today = report_email.attachments.find { |attachment| attachment.filename.starts_with?("(#{client_name})-total_hours_billed_for_day") }
      parsed_csv_report_for_today = CSV.parse(attached_report_for_today.body.raw_source.gsub(/\r\n/, "$"), col_sep: ",", row_sep: "$")

      client_logs_for_today = @logs_for_today.select { |log| log.properties['for_what_client'] == client_name }

      client_total_hours_for_today = client_logs_for_today.map { |log| log.properties['how_much_time_in_hours_spent'].to_f }.sum
      assert_equal client_total_hours_for_today, parsed_csv_report_for_today[0][2].to_f
      total_hours_billed_for_day += client_total_hours_for_today

      client_logs_for_today.each_with_index do |log, index|
        row = 3 + index
        assert_equal log.created_at.to_s, parsed_csv_report_for_today[row][0]
        assert_equal log.properties['how_much_time_in_hours_spent'], parsed_csv_report_for_today[row][1].to_f
        assert_equal log.properties['email_address'] || log.user&.email, parsed_csv_report_for_today[row][2]
        assert_equal log.properties['for_what_client'], parsed_csv_report_for_today[row][3]
        assert_equal log.properties['what_task_did_you_work_on'], parsed_csv_report_for_today[row][4]
        assert_equal log.properties['notes'], parsed_csv_report_for_today[row][5]
      end

      # CSV report for the billables hour for week
      attached_report_for_week = report_email.attachments.find { |attachment| attachment.filename.starts_with?("(#{client_name})-total_hours_billed_for_week") }
      parsed_csv_report_for_week = CSV.parse(attached_report_for_week.body.raw_source.gsub(/\r\n/, "$"), col_sep: ",", row_sep: "$")

      client_logs_for_week = @logs_for_week.select { |log| log.properties['for_what_client'] == client_name }

      client_total_hours_for_week = client_logs_for_week.map { |log| log.properties['how_much_time_in_hours_spent'].to_f }.sum
      assert_equal client_total_hours_for_week, parsed_csv_report_for_week[0][2].to_f
      total_hours_billed_for_week += client_total_hours_for_week

      client_logs_for_week.each_with_index do |log, index|
        row = 3 + index
        assert_equal log.created_at.to_s, parsed_csv_report_for_week[row][0]
        assert_equal log.properties['how_much_time_in_hours_spent'], parsed_csv_report_for_week[row][1].to_f
        assert_equal log.properties['email_address'] || log.user&.email, parsed_csv_report_for_week[row][2]
        assert_equal log.properties['for_what_client'], parsed_csv_report_for_week[row][3]
        assert_equal log.properties['what_task_did_you_work_on'], parsed_csv_report_for_week[row][4]
        assert_equal log.properties['notes'], parsed_csv_report_for_week[row][5]
      end

      # CSV report for the billables hour for month
      attached_report_for_month = report_email.attachments.find { |attachment| attachment.filename.starts_with?("(#{client_name})-total_hours_billed_for_month") }
      parsed_csv_report_for_month = CSV.parse(attached_report_for_month.body.raw_source.gsub(/\r\n/, "$"), col_sep: ",", row_sep: "$")

      client_logs_for_month = @logs_for_month.select { |log| log.properties['for_what_client'] == client_name }

      client_total_hours_for_month = client_logs_for_month.map { |log| log.properties['how_much_time_in_hours_spent'].to_f }.sum
      assert_equal client_total_hours_for_month, parsed_csv_report_for_month[0][2].to_f
      total_hours_billed_for_month += client_total_hours_for_month

      client_logs_for_month.each_with_index do |log, index|
        row = 3 + index
        assert_equal log.created_at.to_s, parsed_csv_report_for_month[row][0]
        assert_equal log.properties['how_much_time_in_hours_spent'], parsed_csv_report_for_month[row][1].to_f
        assert_equal log.properties['email_address'] || log.user&.email, parsed_csv_report_for_month[row][2]
        assert_equal log.properties['for_what_client'], parsed_csv_report_for_month[row][3]
        assert_equal log.properties['what_task_did_you_work_on'], parsed_csv_report_for_month[row][4]
        assert_equal log.properties['notes'], parsed_csv_report_for_month[row][5]
      end
    end

    # The total hours is equal to the sum of all clients total hours billed.
    assert_equal total_hours_billed_for_day, @logs_for_today.map { |log| log.properties['how_much_time_in_hours_spent'].to_f }.sum
    assert_equal total_hours_billed_for_week, @logs_for_week.map { |log| log.properties['how_much_time_in_hours_spent'].to_f }.sum
    assert_equal total_hours_billed_for_month, @logs_for_month.map { |log| log.properties['how_much_time_in_hours_spent'].to_f }.sum
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

    # When REPORTING_EMAILS metadata is empty string
    @billables_report_plugin.update(metadata: {'REPORTING_EMAILS': ''})

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
    current_time = Time.zone.now

    # logs of today
    today_log_1 = api_resources(:tracker_entry_one)
    today_log_2 = api_resources(:tracker_entry_three)
    today_log_2.update(created_at: today_log_2.created_at - 3.minutes)
    today_log_3 = @billables_report_plugin.api_namespace.api_resources.create(today_log_1.as_json.except('id').merge('created_at': current_time - (24.hours - 5.minutes)))

    # logs for week
    start_of_week_time = current_time.beginning_of_week.beginning_of_day
    week_log_1 = @billables_report_plugin.api_namespace.api_resources.create(today_log_2.as_json.except('id').merge('created_at': start_of_week_time))
    week_log_2 = @billables_report_plugin.api_namespace.api_resources.create(today_log_3.as_json.except('id').merge('created_at': start_of_week_time + 2.minutes))

    # logs for month
    start_of_month_time = current_time.beginning_of_month.beginning_of_day
    month_log_1 = @billables_report_plugin.api_namespace.api_resources.create(today_log_2.as_json.except('id').merge('created_at': start_of_month_time))
    month_log_2 = @billables_report_plugin.api_namespace.api_resources.create(today_log_3.as_json.except('id').merge('created_at': start_of_month_time + 2.minutes))

    out_of_scope_for_today = @billables_report_plugin.api_namespace.api_resources.create(today_log_1.as_json.except('id').merge('created_at': current_time - (24.hours + 1.minute)))
    out_of_scope_for_week = @billables_report_plugin.api_namespace.api_resources.create(today_log_2.as_json.except('id').merge('created_at': start_of_week_time - 1.minute))
    out_of_scope_for_month = @billables_report_plugin.api_namespace.api_resources.create(today_log_3.as_json.except('id').merge('created_at': start_of_month_time - 1.minute))

    collection = [month_log_1, month_log_2, week_log_1, week_log_2, today_log_1, today_log_2, today_log_3, out_of_scope_for_today, out_of_scope_for_week, out_of_scope_for_month].map(&:id)

    @logs_for_today = @tracker.api_resources.where(id: collection).where("created_at >= ?", current_time - 24.hours).order(:created_at)
    @logs_for_week = @tracker.api_resources.where(id: collection).where("created_at >= ?", start_of_week_time).order(:created_at)
    @logs_for_month = @tracker.api_resources.where(id: collection).where("created_at >= ?", start_of_month_time).order(:created_at)
  end
end
