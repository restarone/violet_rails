require "test_helper"

class TimesheetRequestPluginTest < ActiveSupport::TestCase
  setup do
    @consultant = api_resources(:consultant_one)
    @timesheet_request = api_namespaces(:timesheet_request)
    @api_action = api_actions(:custom_api_action_on_timesheet_request)

    @api_resource_date_range = api_resources(:timesheet_request_date_range_previous_month)
    @api_resource_current_month = api_resources(:timesheet_request_current_month)

    # Setting current_user for custom_api_action
    Current.user = users(:one) # test@restarone.solutions

    Sidekiq::Testing::fake!
  end

  test "Should send email on requesting timesheet" do
    @api_action.update({
      api_resource_id: @api_resource_current_month.id
    })

    perform_enqueued_jobs do 
      @api_action.execute_action
    end

    sent_email = ActionMailer::Base.deliveries.last
    
    assert_equal 1, sent_email.attachments.length
  end

  test "Should get all the hours for current month" do
    @api_action.update({
      api_resource_id: @api_resource_current_month.id
    })

    perform_enqueued_jobs do 
      @api_action.execute_action
    end

    sent_email = ActionMailer::Base.deliveries.last
    csv_file = sent_email.attachments[0]
    
    parsed_csv = CSV.parse(csv_file.body.raw_source.gsub(/\r\n/, "$"), col_sep: ",", row_sep: "$")

    rate = @consultant.properties["rate"]
    assert_equal rate, parsed_csv[0][2].to_d

    entries = [
      api_resources(:tracker_entry_one), 
      api_resources(:tracker_entry_three)
    ]

    csv_tasks = []
    entries.each { | entry | csv_tasks.push([
      entry.created_at.to_s,
      entry.properties["how_much_time_in_hours_spent"].to_s,
      entry.properties["email_address"],
      entry.properties["for_what_client"],
      entry.properties["what_task_did_you_work_on"],
      entry.properties["notes"]
    ]) } 

    csv_tasks.each { | task | assert parsed_csv.include?(task) }
    
    grand_total = 0
    entries.each { | entry | grand_total += entry.properties["how_much_time_in_hours_spent"]}
    grand_total *= rate
    assert_equal grand_total, parsed_csv[2][2].to_d
  end

  test "Should get all the hours for specified time period" do
    @api_action.update!({
      api_resource_id: @api_resource_date_range.id,
    })

    perform_enqueued_jobs do 
      @api_action.execute_action
    end

    sent_email = ActionMailer::Base.deliveries.last
    csv_file = sent_email.attachments[0]
    
    parsed_csv = CSV.parse(csv_file.body.raw_source.gsub(/\r\n/, "$"), col_sep: ",", row_sep: "$")
    rate = @consultant.properties["rate"]
    assert_equal rate, parsed_csv[0][2].to_d

    entry_one = api_resources(:previous_month_tracker_entry_two)
    assert_equal entry_one.properties["how_much_time_in_hours_spent"], parsed_csv[1][2].to_d
    assert_equal entry_one.properties["for_what_client"], parsed_csv[5][3]
    assert_equal entry_one.properties["notes"], parsed_csv[5][5]

    grand_total = entry_one.properties["how_much_time_in_hours_spent"] * rate
    assert_equal grand_total, parsed_csv[2][2].to_d
  end

  test "Should send an email without timesheet for inactive consultants" do
    @consultant.update({
      properties: @consultant.properties.merge({ active: false })
    })

    @api_action.update!({
      api_resource_id: @api_resource_date_range.id,
    })

    perform_enqueued_jobs do 
      @api_action.execute_action
    end

    sent_email = ActionMailer::Base.deliveries.last
    assert_equal 0, sent_email.attachments.length
    assert_equal "Unable to generate timesheet", sent_email.subject
    assert sent_email.body.include?("Inactive consultants cannot request timesheet")
  end

  test "Should send an email without timesheet if consultant's rate is invalid" do
    @consultant.update({
        properties: @consultant.properties.merge({ rate: "20.0$" })
    })

    @api_action.update!({
        api_resource_id: @api_resource_date_range.id,
    })

    perform_enqueued_jobs do 
        @api_action.execute_action
    end

    sent_email = ActionMailer::Base.deliveries.last
    assert_equal 0, sent_email.attachments.length
    assert_equal "Unable to generate timesheet", sent_email.subject
    assert sent_email.body.include?("Invalid hourly rate for consultant")
  end


  test "Should send an email without timesheet for non existing consultants" do
    @consultant.delete

    @api_action.update!({
      api_resource_id: @api_resource_date_range.id,
    })

    perform_enqueued_jobs do 
      @api_action.execute_action
    end

    sent_email = ActionMailer::Base.deliveries.last
    assert_equal 0, sent_email.attachments.length
    assert_equal "Unable to generate timesheet", sent_email.subject
    assert sent_email.body.include?("Please register as a consultant")
  end
end
