require "test_helper"

class Admin::SubdomainRequestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @public_subdomain = @user.subdomain
    @restarone_subdomain = Subdomain.find_by(name: 'restarone').name
    Apartment::Tenant.switch @restarone_subdomain do
      @restarone_user = User.find_by(email: 'contact@restarone.com')
      @restarone_user.update(global_admin: true)
    end
  end


  test 'allows #index if global admin from public schema' do
    @user.update(global_admin: true)
    assert @user.global_admin
    sign_in(@user)
    get admin_subdomain_requests_url
    assert_response :success
    assert_template :index
  end

  test 'denies #index if spoofed global admin' do
    Apartment::Tenant.switch @restarone_subdomain do
      begin
        sign_in(@restarone_user)
        get admin_subdomain_requests_url
        assert_response :success
        assert_template :index
        rescue ActionController::RoutingError => e
          assert e.message
      else
        raise StandardError.new "ActionController::RoutingError NOT RAISED!"
      end
    end
  end

  test 'denies #index if not global admin' do      
    begin
        refute @user.global_admin
        sign_in(@user)
        get admin_subdomain_requests_url
        assert_response :success
        assert_template :index
    rescue ActionController::RoutingError => e
        assert e.message
    else
      raise StandardError.new "ActionController::RoutingError NOT RAISED!"
    end
  end

  test 'allows #edit if global admin' do
    skip
  end

  test 'denies #edit if not global admin' do
    skip
  end

  test 'allows #show if global admin' do
    skip
  end

  test 'denies #show if not global admin' do
    skip
  end

  test 'allows #update if global admin' do
    skip
  end

  test 'denies #update if not global admin' do
    skip
  end

  test 'allows #destroy if global admin' do
    skip
  end

  test 'denies #destroy if not global admin' do
    skip
  end
end
