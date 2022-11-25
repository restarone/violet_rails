require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  setup do
    @subdomain = subdomains(:public)
    @user = users(:public)
    @subdomain.update(analytics_report_frequency: '1.week')
  end
  
  test 'does not send email to users who are not permissioned to see ' do
    email = UserMailer.analytics_report(@subdomain)
    assert_emails 0 do
      email.deliver_later
    end
  end
  
  test 'sends email to users who are permissioned to see ' do
    @user.update(deliver_analytics_report: true)
    email = UserMailer.analytics_report(@subdomain)
    assert_emails 1 do
      email.deliver_later
    end

    assert_equal email.to, [@user.email]
    assert_in_delta @subdomain.analytics_report_last_sent, Time.zone.now.at_beginning_of_day, 1
  end

  test 'sends OTP in email to user when 2fa is enabled' do
    subdomain = Subdomain.current
    subdomain.update(enable_2fa: true)

    assert_emails 1 do
      UserMailer.send_otp(@user).deliver_later
    end

    last_email  = ActionMailer::Base.deliveries.last
    assert_equal "OTP", last_email.subject
    assert_equal last_email.to, [@user.email]
    assert_match Rails.application.routes.url_helpers.root_url(subdomain: subdomain.name, host: ENV['APP_HOST']), last_email.body.to_s
    assert_match @user.reload.current_otp, last_email.body.to_s
  end
end
