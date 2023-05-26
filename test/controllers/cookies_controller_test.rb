require "test_helper"

class CookiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @subdomain = Subdomain.current
    @subdomain.update(cookies_consent_ui: 'We use cookies', tracking_enabled: true)
  end

  test "should get index" do
    get cookies_url
    assert_response :redirect
  end

  test "should set cookies_accepted cookies and should not show cookies consent UI if cookies_accpected cookie is not nil for html request" do
    get cookies_url(format: :html), params: { cookies: true}
    assert_equal 'true', response.cookies['cookies_accepted']

    get cookies_url(format: :html), params: { cookies: false}
    assert_equal 'false', response.cookies['cookies_accepted']
  end

  test "should set/reset cookies_accepted cookies accordingly for turbo request" do
    get cookies_url(format: :turbo), params: { cookies: true}
    assert_equal 'true', response.cookies['cookies_accepted']

    get cookies_url(format: :turbo), params: { cookies: false}
    assert_equal 'false', response.cookies['cookies_accepted']
  end

  test "should set/reset cookies_accepted cookies accordingly for json request" do
    get cookies_url(format: :json), params: { cookies: true}
    assert_equal 'true', response.cookies['cookies_accepted']

    get cookies_url(format: :json), params: { cookies: false}
    assert_equal 'false', response.cookies['cookies_accepted']
  end

  test "should set/reset cookies_accepted cookies accordingly for ajax request" do
    get cookies_url, params: { cookies: true}, xhr: true
    assert_equal 'true', response.cookies['cookies_accepted']

    get cookies_url, params: { cookies: false}, xhr: true
    assert_equal 'false', response.cookies['cookies_accepted']
  end

  test 'should return cookie information if the cookie consent information was accepted.' do
    @subdomain.update(tracking_enabled: true)
    get cookies_url, params: { cookies: true}

    get cookies_fetch_url

    assert_response :success
    assert_equal ['cookies_accepted', 'ahoy_visitor_token', 'ahoy_visit_token', 'metadata'].sort, response.parsed_body.keys.sort
  end

  test 'should not return cookie information if the cookie consent information was rejected.' do
    @subdomain.update(tracking_enabled: true)
    get cookies_url, params: { cookies: false}

    get cookies_fetch_url

    assert_response :success
    assert_equal ['message', 'metadata'], response.parsed_body.keys
    assert_equal 'Cookies were rejected or has not been accepted.', response.parsed_body['message']
  end

  test 'should return geolocation data if cookie consent was accepted' do
    stub_request(:get, /http:\/\/ip-api.com\/json\/*/).to_return(status: 429, body: {
      status: "success",
      country: "Australia",
      countryCode: "AU",
      region: "ACT",
      regionName: "Australian Capital Territory",
      city: "Canberra",
      zip: "2604",
      lat: -35.3122,
      lon: 149.1511,
      timezone: "Australia/Sydney",
      isp: "SingTel Optus Pty Ltd",
      org: "Optus Internet Pty Ltd",
      as: "AS4804 Microplex PTY LTD",
      query: "110.33.122.75"
    }.to_json)
    self.remote_addr = '110.33.122.75' # random IP of Australia
    
    @subdomain.update(tracking_enabled: true)

    get cookies_url, params: { cookies: true}
    get cookies_fetch_url

    assert_response :success
    assert_equal ['cookies_accepted', 'ahoy_visitor_token', 'ahoy_visit_token', 'metadata'].sort, response.parsed_body.keys.sort
    
    metadata = response.parsed_body['metadata']
    assert metadata
    assert_equal '110.33.122.75', metadata['ip_address']
    assert_equal request.safe_location.country, metadata['country']
    assert_equal request.safe_location.country_code, metadata['country_code']
  end

  test 'should return geolocation data even if cookie consent was rejected' do
    stub_request(:get, /http:\/\/ip-api.com\/json\/*/).to_return(status: 429, body: {
      status: "success",
      country: "Australia",
      countryCode: "AU",
      region: "ACT",
      regionName: "Australian Capital Territory",
      city: "Canberra",
      zip: "2604",
      lat: -35.3122,
      lon: 149.1511,
      timezone: "Australia/Sydney",
      isp: "SingTel Optus Pty Ltd",
      org: "Optus Internet Pty Ltd",
      as: "AS4804 Microplex PTY LTD",
      query: "110.33.122.75"
    }.to_json)

    self.remote_addr = '110.33.122.75' # random IP of Australia
    
    @subdomain.update(tracking_enabled: true)

    get cookies_url, params: { cookies: false}

    get cookies_fetch_url

    assert_response :success
    assert_equal 'Cookies were rejected or has not been accepted.', response.parsed_body['message']
    
    metadata = response.parsed_body['metadata']
    assert metadata
    assert_equal '110.33.122.75', metadata['ip_address']
    assert_equal request.safe_location.country, metadata['country']
    assert_equal request.safe_location.country_code, metadata['country_code']
  end

  test 'should return geolocation data accordingly when the country location details cannot be determined from IP' do
    self.remote_addr = '127.0.0.1' # localhost IP
    
    @subdomain.update(tracking_enabled: true)

    get cookies_url, params: { cookies: true}
    get cookies_fetch_url

    assert_response :success
    assert_equal ['cookies_accepted', 'ahoy_visitor_token', 'ahoy_visit_token', 'metadata'].sort, response.parsed_body.keys.sort
    
    metadata = response.parsed_body['metadata']
    assert metadata
    assert_equal '127.0.0.1', metadata['ip_address']
    assert_equal 'not available', metadata['country']
    assert_equal 'not available', metadata['country_code']
  end

  test 'should not throw error if the API limit is crossed' do
    stub_request(:get, /http:\/\/ip-api.com\/json\/*/).to_return(status: 429, body: {
      query: "110.41.52.64",
      status: "fail",
      message: "API usage limit exceeded!",
    }.to_json)
    self.remote_addr = '110.41.52.64'
    @subdomain.update(tracking_enabled: true)

    assert_nothing_raised do 
      get cookies_url, params: { cookies: false}

      get cookies_fetch_url
    end

    assert_response :success
    assert_equal ['message', 'metadata'].sort, response.parsed_body.keys.sort
    
    metadata = response.parsed_body['metadata']
    assert metadata
    assert_equal '110.41.52.64', metadata['ip_address']
    assert_equal 'not available', metadata['country']
    assert_equal 'not available', metadata['country_code']
  end
end
