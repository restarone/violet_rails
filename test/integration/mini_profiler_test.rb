require "test_helper"

class Rack::MiniProfilerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.env.stubs(:test?).returns(false)
    Rack::MiniProfiler::ClientSettings.any_instance.stubs(:has_valid_cookie?).returns(true)

    @restarone_subdomain = Subdomain.find_by(name: 'restarone')
    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user = User.find_by(email: 'contact@restarone.com')
      @restarone_user.update(can_manage_analytics: true)
    end
  end

  test "should show mini-profiler badge if user is permissioned properly" do
    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user.update(can_access_admin: true, show_profiler: true)

      sign_in(@restarone_user)
      get v2_dashboard_url(subdomain: @restarone_subdomain.name)

      assert_response :success
      assert response.headers.has_key?('X-MiniProfiler-Ids')
      assert response.body.include?('/mini-profiler-resources/includes.js')
    end
  end

  test "should not show mini-profiler badge if user cannot access admin or profiler" do
    # In unhappy case, the cookies are invalid.
    Rack::MiniProfiler::ClientSettings.any_instance.stubs(:has_valid_cookie?).returns(false)

    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user.update(can_access_admin: false, show_profiler: true)

      sign_in(@restarone_user)
      get v2_dashboard_url(subdomain: @restarone_subdomain.name)
      assert_response :redirect

      refute response.headers.has_key?('X-MiniProfiler-Ids')
      refute response.body.include?('/mini-profiler-resources/includes.js')
      
      @restarone_user.update(can_access_admin: true, show_profiler: false)

      sign_in(@restarone_user)
      get v2_dashboard_url(subdomain: @restarone_subdomain.name)
      assert_response :success

      refute response.headers.has_key?('X-MiniProfiler-Ids')
      refute response.body.include?('/mini-profiler-resources/includes.js')
    end
  end

  # pp=env - START
  test "should show env details only if the user is properly permissioned and also a global_admin" do
    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user.update(can_access_admin: true, show_profiler: true, global_admin: true)

      sign_in(@restarone_user)
      get v2_dashboard_url(subdomain: @restarone_subdomain.name), params: { pp: 'env' }

      assert_response :success
      assert response.headers['Content-Type'].include?('text/plain')
      assert_match 'QUERY_STRING', response.body
      assert_match "Rack Environment\n---------------", response.body
    end
  end

  test "should not show env details if the user is properly permissioned but not a global_admin" do
    # In unhappy case, the cookies are invalid.
    Rack::MiniProfiler::ClientSettings.any_instance.stubs(:has_valid_cookie?).returns(false)

    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user.update(can_access_admin: true, show_profiler: true, global_admin: false)

      sign_in(@restarone_user)
      get v2_dashboard_url(subdomain: @restarone_subdomain.name), params: { pp: 'env' }

      assert_response :success
      refute response.headers['Content-Type'].include?('text/plain')
      refute_match 'QUERY_STRING', response.body
      refute_match "Rack Environment\n---------------", response.body
      refute response.headers.has_key?('X-MiniProfiler-Ids')
      refute response.body.include?('/mini-profiler-resources/includes.js')
    end
  end

  test "should not show env details if the user is global_admin but not properly permissioned" do
    # In unhappy case, the cookies are invalid.
    Rack::MiniProfiler::ClientSettings.any_instance.stubs(:has_valid_cookie?).returns(false)

    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user.update(can_access_admin: true, show_profiler: false, global_admin: true)

      sign_in(@restarone_user)
      get v2_dashboard_url(subdomain: @restarone_subdomain.name), params: { pp: 'env' }

      assert_response :success
      refute response.headers['Content-Type'].include?('text/plain')
      refute_match 'QUERY_STRING', response.body
      refute_match "Rack Environment\n---------------", response.body
      refute response.headers.has_key?('X-MiniProfiler-Ids')
      refute response.body.include?('/mini-profiler-resources/includes.js')

      @restarone_user.update(can_access_admin: false, show_profiler: true, global_admin: true)

      sign_in(@restarone_user)
      get v2_dashboard_url(subdomain: @restarone_subdomain.name), params: { pp: 'env' }

      assert_response :redirect
      refute response.headers['Content-Type'].include?('text/plain')
      refute_match 'QUERY_STRING', response.body
      refute_match "Rack Environment\n---------------", response.body
      refute response.headers.has_key?('X-MiniProfiler-Ids')
      refute response.body.include?('/mini-profiler-resources/includes.js')
    end
  end
  # pp=env - END

  # OTHER pp values - START

  # pp=profile-memory - START
  test "should show profile-memory details if the user is properly permissioned regardless of being global_admin" do
    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user.update(can_access_admin: true, show_profiler: true, global_admin: false)
      sign_in(@restarone_user)

      get v2_dashboard_url(subdomain: @restarone_subdomain.name), params: { pp: 'profile-memory' }

      assert_response :success
      assert response.headers['Content-Type'].include?('text/plain')
      refute response.headers['Content-Type'].include?('text/html')
      assert_match 'Total allocated:', response.body
      assert_match 'Total retained:', response.body
      assert_match 'allocated memory by gem', response.body
      assert_match 'allocated memory by file', response.body
      assert_match 'allocated memory by location', response.body
      assert_match 'allocated memory by class', response.body
      assert_match 'allocated objects by gem', response.body
      assert_match 'allocated objects by file', response.body
      assert_match 'allocated objects by location', response.body
      assert_match 'allocated objects by class', response.body
      assert_match 'retained memory by gem', response.body
      assert_match 'retained memory by file', response.body
      assert_match 'retained memory by location', response.body
      assert_match 'retained memory by class', response.body
      assert_match 'retained objects by gem', response.body
      assert_match 'retained objects by file', response.body
      assert_match 'retained objects by location', response.body
      assert_match 'retained objects by class', response.body
    end
  end

  test "should not show profile-memory details if the user is not properly permissioned" do
    # In unhappy case, the cookies are invalid.
    Rack::MiniProfiler::ClientSettings.any_instance.stubs(:has_valid_cookie?).returns(false)

    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user.update(can_access_admin: true, show_profiler: false, global_admin: false)
      sign_in(@restarone_user)

      get v2_dashboard_url(subdomain: @restarone_subdomain.name), params: { pp: 'profile-memory' }

      assert_response :success
      assert response.headers['Content-Type'].include?('text/html')
      refute response.headers['Content-Type'].include?('text/plain')

      refute_match 'Total allocated:', response.body
      refute_match 'Total retained:', response.body
      refute_match 'allocated memory by gem', response.body
      refute_match 'allocated memory by file', response.body
      refute_match 'allocated memory by location', response.body
      refute_match 'allocated memory by class', response.body
      refute_match 'allocated objects by gem', response.body
      refute_match 'allocated objects by file', response.body
      refute_match 'allocated objects by location', response.body
      refute_match 'allocated objects by class', response.body
      refute_match 'retained memory by gem', response.body
      refute_match 'retained memory by file', response.body
      refute_match 'retained memory by location', response.body
      refute_match 'retained memory by class', response.body
      refute_match 'retained objects by gem', response.body
      refute_match 'retained objects by file', response.body
      refute_match 'retained objects by location', response.body
      refute_match 'retained objects by class', response.body
    end
  end
  # pp=profile-memory - END
  
  # pp=profile-gc - START
  test "should show profile-gc details if the user is properly permissioned regardless of being global_admin" do
    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user.update(can_access_admin: true, show_profiler: true, global_admin: false)
      sign_in(@restarone_user)
      
      get v2_dashboard_url(subdomain: @restarone_subdomain.name), params: { pp: 'profile-gc' }
      
      assert_response :success
      assert response.headers['Content-Type'].include?('text/plain')
      refute response.headers['Content-Type'].include?('text/html')

      assert_match 'Initial state: object count:', response.body
      assert_match 'Memory allocated outside heap (bytes):', response.body
      assert_match 'GC Stats:', response.body
      assert_match 'ObjectSpace delta caused by request:', response.body
      assert_match 'ObjectSpace stats:', response.body
      assert_match 'String stats:', response.body
    end
  end

  test "should not show profile-gc details if the user is not properly permissioned" do
    # In unhappy case, the cookies are invalid.
    Rack::MiniProfiler::ClientSettings.any_instance.stubs(:has_valid_cookie?).returns(false)

    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user.update(can_access_admin: true, show_profiler: true, global_admin: false)
      sign_in(@restarone_user)
      
      get v2_dashboard_url(subdomain: @restarone_subdomain.name), params: { pp: 'profile-gc' }
      
      assert_response :success
      refute response.headers['Content-Type'].include?('text/plain')
      assert response.headers['Content-Type'].include?('text/html')

      refute_match 'Initial state: object count:', response.body
      refute_match 'Memory allocated outside heap (bytes):', response.body
      refute_match 'GC Stats:', response.body
      refute_match 'ObjectSpace delta caused by request:', response.body
      refute_match 'ObjectSpace stats:', response.body
      refute_match 'String stats:', response.body
    end
  end
  # pp=profile-gc - END
  
  # pp=analyze-memory - START
  test "should show analyze-memory details if the user is properly permissioned regardless of being global_admin" do
    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user.update(can_access_admin: true, show_profiler: true, global_admin: false)
      sign_in(@restarone_user)
      
      get v2_dashboard_url(subdomain: @restarone_subdomain.name), params: { pp: 'analyze-memory' }
      
      assert_response :success
      assert response.headers['Content-Type'].include?('text/plain')
      refute response.headers['Content-Type'].include?('text/html')

      assert_match 'ObjectSpace stats:', response.body
      assert_match '1000 Largest strings:', response.body
    end
  end

  test "should not show analyze-memory details if the user is not properly permissioned" do
    # In unhappy case, the cookies are invalid.
    Rack::MiniProfiler::ClientSettings.any_instance.stubs(:has_valid_cookie?).returns(false)

    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user.update(can_access_admin: true, show_profiler: true, global_admin: false)
      sign_in(@restarone_user)
      
      get v2_dashboard_url(subdomain: @restarone_subdomain.name), params: { pp: 'analyze-memory' }
      
      assert_response :success
      refute response.headers['Content-Type'].include?('text/plain')
      assert response.headers['Content-Type'].include?('text/html')

      refute_match 'ObjectSpace stats:', response.body
      refute_match '1000 Largest strings:', response.body
    end
  end
  # pp=analyze-memory - END
  
  # pp=trace-exceptions - START
  test "should show trace-exceptions details if the user is properly permissioned regardless of being global_admin" do
    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user.update(can_access_admin: true, show_profiler: true, global_admin: false)
      sign_in(@restarone_user)
      
      get v2_dashboard_url(subdomain: @restarone_subdomain.name), params: { pp: 'trace-exceptions' }
      
      assert_response :success
      assert response.headers['Content-Type'].include?('text/plain')
      refute response.headers['Content-Type'].include?('text/html')

      assert_match 'Exceptions raised during request', response.body
    end
  end

  test "should not show trace-exceptions details if the user is not properly permissioned" do
    # In unhappy case, the cookies are invalid.
    Rack::MiniProfiler::ClientSettings.any_instance.stubs(:has_valid_cookie?).returns(false)

    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user.update(can_access_admin: true, show_profiler: true, global_admin: false)
      sign_in(@restarone_user)
      
      get v2_dashboard_url(subdomain: @restarone_subdomain.name), params: { pp: 'trace-exceptions' }
      
      assert_response :success
      refute response.headers['Content-Type'].include?('text/plain')
      assert response.headers['Content-Type'].include?('text/html')

      refute_match 'Exceptions raised during request', response.body
    end
  end
  # pp=trace-exceptions - END
  
  # pp=help - START
  test "should show help details if the user is properly permissioned regardless of being global_admin" do
    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user.update(can_access_admin: true, show_profiler: true, global_admin: false)
      sign_in(@restarone_user)
      
      get v2_dashboard_url(subdomain: @restarone_subdomain.name), params: { pp: 'help' }
      
      assert_response :success
      assert response.headers['Content-Type'].include?('text/html')

      assert_match "This is the help menu of the <a href='https://github.com/MiniProfiler/rack-mini-profiler'>rack-mini-profiler</a> gem, append the following to your query string for more options:", response.body
    end
  end

  test "should not show help details if the user is not properly permissioned" do
    # In unhappy case, the cookies are invalid.
    Rack::MiniProfiler::ClientSettings.any_instance.stubs(:has_valid_cookie?).returns(false)

    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user.update(can_access_admin: true, show_profiler: true, global_admin: false)
      sign_in(@restarone_user)
      
      get v2_dashboard_url(subdomain: @restarone_subdomain.name), params: { pp: 'help' }
      
      assert_response :success
      assert response.headers['Content-Type'].include?('text/html')

      refute_match "This is the help menu of the <a href='https://github.com/MiniProfiler/rack-mini-profiler'>rack-mini-profiler</a> gem, append the following to your query string for more options:", response.body
    end
  end
  # pp=help - END

  # OTHER pp values - END
end