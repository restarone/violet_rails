require "test_helper"

class AnalyticsReportServiceTest  < ActiveSupport::TestCase
  setup do 
    @subdomain = subdomains(:public)
    @subdomain.update(analytics_report_frequency: '1.week')
  end

  test "returns expected response" do
    report = AnalyticsReportService.new(@subdomain).call
 
    assert_equal report[:visits][:country]["canada"], 1
    assert_equal report[:visits][:city]["toronto"], 1
    assert_equal report[:visits][:region]["onterio"], 1
    assert_equal report[:visits][:referring_domain]["localhost"], 1
    assert_equal report[:visits][:landing_page]["http://lvh.me:5250/"], 1 
    assert_equal report[:users].count, 1
    assert_equal report[:macros], {users: {total: 2, added: 1}, pages: {total: 1, added: 1}, storage: {total: "0 Bytes", added: "0 Bytes"}}
  end
    
end