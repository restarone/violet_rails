require "test_helper"

class Admin::SubdomainRequestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(global_admin: true)
    @public_subdomain = @user.subdomain
    @restarone_subdomain = Subdomain.find_by(name: 'restarone').name
    Apartment::Tenant.switch @restarone_subdomain do
      @restarone_user = User.find_by(email: 'contact@restarone.com')
    end
    @subdomain_request = subdomain_requests(:default)
  end


  test 'allows #index if global admin from public schema' do
    assert @user.global_admin
    sign_in(@user)
    get admin_subdomain_requests_url
    assert_response :success
    assert_template :index
    assert_template layout: "admin"
  end

  test 'denies #index if global admin from not public schema (restarone)' do
    @restarone_user.update(global_admin: true)
    Apartment::Tenant.switch @restarone_subdomain do
      sign_in(@restarone_user)
      get admin_subdomain_requests_url
      assert flash.alert
      assert_response :redirect
    end
  end

  test 'denies #index if not global admin (restarone)' do
    @restarone_user.update(global_admin: false)
    Apartment::Tenant.switch @restarone_subdomain do
      sign_in(@restarone_user)
      get admin_subdomain_requests_url
      assert flash.alert
      assert_response :redirect
    end
  end

  test 'denies #index if not global admin' do   
    @user.update(global_admin: false)
    refute @user.global_admin
    sign_in(@user)
    get admin_subdomain_requests_url
    assert flash.alert
    assert_response :redirect
  end

  test 'allows #edit if global admin' do
    sign_in(@user)
    get edit_admin_subdomain_request_url(id: @subdomain_request.slug)
    assert_response :success
    assert_template :edit
  end

  test 'denies #edit if not global admin' do
    @user.update(global_admin: false)
    refute @user.global_admin
    sign_in(@user)
    get edit_admin_subdomain_request_url(id: @subdomain_request.slug)
    assert flash.alert
    assert_response :redirect
  end

  test 'allows #show if global admin' do
    sign_in(@user)
    get admin_subdomain_request_url(id: @subdomain_request.slug)
    assert_response :success
    assert_template :show
  end

  test 'denies #show if not global admin' do
    @user.update(global_admin: false)
    refute @user.global_admin
    sign_in(@user)
    get admin_subdomain_request_url(id: @subdomain_request.slug)
    assert flash.alert
    assert_response :redirect
  end

  test 'allows #update if global admin' do
    sign_in(@user)
    patch admin_subdomain_request_url(id: @subdomain_request.slug)
    assert_response :success
    assert_template :update
  end

  test 'denies #update if not global admin' do
    @user.update(global_admin: false)
    sign_in(@user)
    patch admin_subdomain_request_url(id: @subdomain_request.slug)
    assert flash.alert
    assert_response :redirect
  end

  test 'allows #destroy if global admin' do
    sign_in(@user)
    delete admin_subdomain_request_url(id: @subdomain_request.slug)
    assert_response :success
  end

  test 'denies #destroy if not global admin' do
    @user.update(global_admin: false)
    sign_in(@user)
    delete admin_subdomain_request_url(id: @subdomain_request.slug)
    assert flash.alert
    assert_response :redirect
  end

  test 'allows #approve if global admin' do
    assert_difference "SubdomainRequest.all.size", -1 do
      assert_difference "Subdomain.all.size", +1 do
        sign_in(@user)
        assert_changes "Devise.mailer.deliveries.size" do
          get approve_admin_subdomain_request_url(id: @subdomain_request.slug)
        end
        Apartment::Tenant.switch Subdomain.last.name do
          assert User.all.size > 0
          user = User.first
          User::FULL_PERMISSIONS.keys.each{|k, v| assert user.send(k) }
          public_site = Comfy::Cms::Site.find_by(hostname: Subdomain.last.hostname)
          assert Mailbox.first
          assert public_site
          default_layout = public_site.layouts.first
          assert default_layout
          default_page = default_layout.pages.first
          assert default_page
          assert default_page.fragments.any?
        end
        assert_redirected_to admin_subdomain_requests_path
      end
    end
  end

  test 'denies #approve if not global admin' do
    @user.update(global_admin: false)
    sign_in(@user)
    assert_no_difference "Subdomain.all.size" do
      get approve_admin_subdomain_request_url(id: @subdomain_request.slug)
      assert flash.alert
      assert_response :redirect
    end
  end

  test 'allows #disapprove if global admin' do
    assert_difference "SubdomainRequest.all.size", -1 do
      sign_in(@user)
      get disapprove_admin_subdomain_request_url(id: @subdomain_request.slug)
      assert_redirected_to admin_subdomain_requests_path
    end
  end

  test 'denies #disapprove if not global admin' do
    @user.update(global_admin: false)
    sign_in(@user)
    assert_no_difference "SubdomainRequest.all.size" do
      get disapprove_admin_subdomain_request_url(id: @subdomain_request.slug)
    end
    assert flash.alert
    assert_response :redirect
  end
end
