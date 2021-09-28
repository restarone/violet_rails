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
    assert_in_delta @subdomain.analytics_report_last_sent, Time.zone.now, 1
  end
end
