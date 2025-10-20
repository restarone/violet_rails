require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.enabled = true
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    @user = users(:public)
    @limit = ENV['REQUEST_PER_MINUTE'].to_i
    @error_limit = ENV['ERROR_PER_MINUTE'].to_i
    Sidekiq::Testing.fake!
  end

  teardown do
    travel_back
    Rails.cache.clear
    Rack::Attack.reset!
    Rack::Attack.enabled = false
  end

  def setup_fake_routes
    Rails.application.routes.draw do
      get '/error', to: -> (env) { 
        raise StandardError
      }
    end
  end

  test 'throttled non admin request' do
    sign_in(@user)
    travel_to Time.zone.now.beginning_of_day

    get '/'

    assert_response :success
  end

  test 'throttle exceeded request' do
    sign_in(@user)

    travel_to Time.zone.now.beginning_of_day
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
    travel_to Time.zone.now.beginning_of_day

    (@limit + 5).times do
      get '/', env: { 'REMOTE_IP': '1.2.3.4' }
      assert_response :success
    end
  end

  test 'exponential backoff' do
    sign_in(@user)
    travel_to Time.zone.now.beginning_of_day

    # activate level 1
    1.upto(@limit + 4) do |i|
      get '/'
      assert_response :success if i < (@limit - 1)
      assert_response 429 if  i > @limit
    end

    travel 45.seconds
    get '/'
    assert_response 429

    # activate level 2
    travel 15.seconds
    1.upto(@limit + 2) do |i|
      get '/'
      assert_response :success if i <= @limit
      assert_response 429 if  i > @limit
    end

    travel 15.seconds
    get '/'
    assert_response 429

    # activate level 3
    travel 45.seconds
    1.upto(@limit + 3) do |i|
      get '/'
      assert_response :success if i <= @limit
      assert_response 429 if  i > @limit
    end

    travel 1.minute
    get '/'
    assert_response 429

    # activate level 4
    travel 1.minute
    1.upto(@limit + 3) do |i|
      get '/'
      assert_response :success if i <= @limit
      assert_response 429 if  i > @limit
    end

    travel 3.minutes
    get '/'
    assert_response 429

    # activate level 5
    travel 1.minute
    1.upto(@limit + 3) do |i|
      get '/'
      assert_response :success if i <= @limit
      assert_response 429 if  i > @limit
    end

    travel 7.minutes
    get '/'
    assert_response 429

    # activate level 6
    travel 1.minute
    1.upto(@limit + 1) do |i|
      get '/'
      assert_response :success if i <= @limit
      assert_response 429 if  i > @limit
    end

    # send limit exceeded email
    perform_enqueued_jobs do
      assert_difference "RackAttackMailer.deliveries.count", +1 do
        get '/'
        Sidekiq::Worker.drain_all
      end
    end
    assert_response 403

    travel 12.hours
    get '/'
    assert_response 302
  end

  test 'error throttle: exponential backoff' do
    setup_fake_routes
    travel_to Time.zone.now.beginning_of_day

    # activate level 1
    1.upto(@error_limit + 2) do |i|
      if i > @error_limit + 1
        get '/error'
        assert_response 429
      else
        assert_raises StandardError do 
          get '/error'
        end
      end
    end

    travel 45.seconds
    get '/error'
    assert_response 429

    # activate level 2
    travel 15.seconds
    1.upto(@error_limit + 1) do |i|
      if i > @error_limit
        get '/error'
        assert_response 429
      else
        assert_raises StandardError do 
          get '/error'
        end
      end
    end

    travel 15.seconds
    get '/error'
    assert_response 429

    # activate level 3
    travel 45.seconds
    travel 15.seconds
    1.upto(@error_limit + 1) do |i|
      if i > @error_limit
        get '/error'
        assert_response 429
      else
        assert_raises StandardError do 
          get '/error'
        end
      end
    end

    travel 1.minute
    get '/error'
    assert_response 429

    # activate level 4
    travel 1.minute
    1.upto(@error_limit + 1) do |i|
      if i > @error_limit
        get '/error'
        assert_response 429
      else
        assert_raises StandardError do 
          get '/error'
        end
      end
    end

    travel 3.minutes
    get '/error'
    assert_response 429

    # activate level 5
    travel 1.minute
    1.upto(@error_limit + 1) do |i|
      if i > @error_limit
        get '/error'
        assert_response 429
      else
        assert_raises StandardError do 
          get '/error'
        end
      end
    end

    travel 7.minutes
    get '/error'
    assert_response 429

    # activate level 6
    travel 1.minute
    1.upto(@error_limit + 1) do |i|
      if i > @error_limit
        get '/error'
        assert_response 429
      else
        assert_raises StandardError do 
          get '/error'
        end
      end
    end

    get '/error'
    assert_response 403

    travel 12.hours
    assert_raises StandardError do 
      get '/error'
    end

    Rails.application.reload_routes!
  end
end