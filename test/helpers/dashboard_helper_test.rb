require 'test_helper'

class DashboardHelperTest < ActionView::TestCase
  test 'redacts devise user links' do
    url = "http://violet.lvh.me:5250/users/confirmation?confirmation_token=fQg7D1kv1d_12f8U_yDX"
    url_2 = "http://violet.lvh.me:5250/users/confirmation?confirmation_token=fQg7D1kv1d_12f8U_yDX"
    url_non_redactable = "http://violet.lvh.me:5250/users/golf"
    assert_equal "private-system-url-redacted" , redact_private_urls(url)
    assert_equal "private-system-url-redacted" , redact_private_urls(url_2)
    assert_equal url_non_redactable , redact_private_urls(url_non_redactable)
  end
end