require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    @user = users(:public)
    ENV['REQUEST_PER_MINUTE'] = '5'
    @limit = ENV['REQUEST_PER_MINUTE'].to_i
  end

  teardown do
    Rack::Attack.reset!
    Rails.cache.clear
    Rack::Attack.cache.store.clear
  end

  test 'throttled non admin request' do
    sign_in(@user)
    get '/'

    assert_response :success
  end

  test 'throttle exceeded request' do
    sign_in(@user)
    (@limit + 5).times do
      get '/'
    end

    assert_response 429
    assert_includes response.body, 'Retry later'
    
    travel 2.minutes
    get '/'
    assert_response :success
  end

  test 'should not throttle for global admins' do
    @user.update(global_admin: true)

    sign_in(@user)
    (@limit + 5).times do
      get '/'
      assert_response :success
    end
  end

  test 'exponential backoff' do  
    1.upto(@limit + 2) do |i|
      get '/'
      assert_response :success if i <= @limit
      assert_response 429 if  i > @limit
    end

    travel 30.seconds
     get '/'
    assert_response 429

    travel 30.seconds
    1.upto(@limit + 2) do |i|
      get '/'
      assert_response :success if i <= @limit
      assert_response 429 if  i > @limit
    end

    travel 2.minutes


    # 1.upto(@limit + 2) do |i|
    #   get '/'
    #   assert_response :success if i <= @limit
    #   assert_response 429 if  i > @limit
    # end

    # travel 1.minutes
    # get '/'
    # assert_response 403

    # travel 2.minutes
    # (@limit + 2).times do |i|
    #   get '/'
    #   assert_response 403 if  i >= @limit
    # end
  end
end