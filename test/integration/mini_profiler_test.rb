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
end