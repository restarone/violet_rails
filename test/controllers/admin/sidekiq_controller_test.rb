require "test_helper"

class Admin::SidekiqControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(global_admin: true)
    @restarone_subdomain = Subdomain.find_by(name: 'restarone').name
    Apartment::Tenant.switch @restarone_subdomain do
      @restarone_user = User.find_by(email: 'contact@restarone.com')
    end
  end


  test 'allows access if global admin from public schema' do
    assert @user.global_admin
    sign_in(@user)
    get admin_sidekiq_web_url
    assert_response :success
  end

  test 'denies access if not global admin from public schema' do
    refute @restarone_user.global_admin
    sign_in(@restarone_user)
    begin
      get admin_sidekiq_web_url
    rescue ActionController::RoutingError => exception
      assert exception
    else
      raise "Routing error not raised, route is exposed to non global admins"
    end
  end
end
