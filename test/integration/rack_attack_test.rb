require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:public)
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  test 'throttled non admin request' do
    sign_in(@user)
    get '/'

    assert_response :success
  end

  test 'throttle exceeded request' do
    sign_in(@user)
    122.times do
      get '/'
    end

    assert_equal 429, response.status
    assert_includes response.body, 'Retry later'
    
    travel 2.minutes
    get '/'
    assert_equal 200, response.status
  end

  test 'exponential backoff' do
    sign_in(@user)
    #  returns 200 for ~120 request with in first minute
    120.times do
      get '/'
    end

    assert_response :success

    # returns 429 for more than 120 request
    get '/'
    get '/'
    assert_equal 429, response.status

    travel 30.seconds
    get '/'
    assert_equal 429, response.status

    # wait 1 minute to send another request
    travel 1.minutes
    get '/'
    assert_response :success

    110.times do
      get '/'
    end
    assert_response :success

    10.times do
      get '/'
    end
    assert_equal 429, response.status


    # wait 1 minute to send another request
    travel 7.minutes
    get '/'
    assert_response :success
  end
end