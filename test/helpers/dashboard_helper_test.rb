require 'test_helper'

class DashboardHelperTest < ActionView::TestCase
  test 'redacts devise user links' do
    url = "http://violet.lvh.me:5250/users/confirmation?confirmation_token=fQg7D1kv1d_12f8U_yDX"
    url_2 = "http://violet.lvh.me:5250/users/confirmation?confirmation_token=fQg7D1kv1d_12f8U_yDX"
    url_3 = "https://violet.restarone.solutions/users/password/edit?reset_password_token=-Es6rYgrrDssyyzVNnA6"
    url_non_redactable = "http://violet.lvh.me:5250/users/golf"
    assert_equal "private-system-url-redacted" , redact_private_urls(url)
    assert_equal "private-system-url-redacted" , redact_private_urls(url_2)
    assert_equal "private-system-url-redacted" , redact_private_urls(url_3)
    assert_equal url_non_redactable , redact_private_urls(url_non_redactable)
  end

  test 'page_name' do
    assert_equal 'Website', page_name(nil)

    page = comfy_cms_pages(:root)
    assert_equal page.label, page_name(page.id)
  end

  test 'display_percent_change' do
    refute display_percent_change(100, 0)

    assert_equal "<div class=\"positive\"><i class=\"pr-2 fa fa-caret-up\"></i>20.0 %</div>", display_percent_change(60, 50)

    assert_equal "<div class=\"negative\"><i class=\"pr-2 fa fa-caret-down\"></i>16.67 %</div>", display_percent_change(50, 60)
  end

  test 'tooltip_content' do
    assert_equal "There's no data from the previous 3 months to compare", tooltip_content(1, 0, '3 months', (Time.now.beginning_of_month - 2.months).to_date, Time.now.end_of_month.to_date)

    assert_equal "This is a 100.0 % increase compared to the previous 6 months", tooltip_content(2, 1, '6 months', (Time.now.beginning_of_month - 5.months).to_date, Time.now.end_of_month.to_date)

    assert_equal "There's no data from the previous month to compare", tooltip_content(1, 0, Date.current.strftime('%B %Y'), Time.now.beginning_of_month.to_date, Time.now.end_of_month.to_date)

    assert_equal "This is a 50.0 % decrease compared to the previous month", tooltip_content(1, 2, Date.current.strftime('%B %Y'), Time.now.beginning_of_month.to_date, Time.now.end_of_month.to_date)

    assert_equal "There's no data from the previous 10 days to compare", tooltip_content(1, 0, 'Custom Interval', (Time.now - 10.days).to_date, Time.now.to_date)

    assert_equal "This is a 100.0 % increase compared to the previous 10 days", tooltip_content(2, 1, 'Custom Range', (Time.now - 10.days).to_date, Time.now.to_date)
  end

  test 'to_minutes' do
    assert_equal '10,000.0 min', to_minutes(10000*1000*60)
  end
end