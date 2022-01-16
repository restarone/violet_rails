require "test_helper"

class Admin::SubdomainsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @user.update(global_admin: true)
    @restarone_subdomain = Subdomain.find_by(name: 'restarone')
    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user = User.find_by(email: 'contact@restarone.com')
    end
  end


  test 'allows #index if global admin from public schema' do
    assert @user.global_admin
    sign_in(@user)
    get admin_subdomains_url
    assert_response :success
    assert_template :index
    assert_template layout: "admin"
  end

  test 'allows #index if global admin (restarone)' do
    @restarone_user.update(global_admin: true)
    Apartment::Tenant.switch @restarone_subdomain.name do
      sign_in(@restarone_user)
      get admin_subdomains_url
      assert_response :success
      assert_template :index
      assert_template layout: "admin"
    end
  end

  test 'denies #index if not global admin (restarone)' do
    @restarone_user.update(global_admin: false)
    Apartment::Tenant.switch @restarone_subdomain.name do
      sign_in(@restarone_user)
      get admin_subdomains_url
      assert flash.alert
      assert_response :redirect
    end
  end

  test 'denies #index if not global admin' do   
    @user.update(global_admin: false)
    refute @user.global_admin
    sign_in(@user)
    get admin_subdomains_url
    assert flash.alert
    assert_response :redirect
  end

  test 'allows #edit if global admin' do
    sign_in(@user)
    get edit_admin_subdomain_url(id: @restarone_subdomain.id)
    assert_response :success
    assert_template :edit
  end

  test 'denies #edit if not global admin' do
    @user.update(global_admin: false)
    refute @user.global_admin
    sign_in(@user)
    get edit_admin_subdomain_url(id: @restarone_subdomain.id)
    assert flash.alert
    assert_response :redirect
  end

  test 'allows #update if global admin' do
    sign_in(@user)
    patch admin_subdomain_url(id: @restarone_subdomain.id)
    assert_response :success
    assert_template :update
  end

  test 'denies #update if not global admin' do
    @user.update(global_admin: false)
    sign_in(@user)
    patch admin_subdomain_url(id: @restarone_subdomain.id)
    assert flash.alert
    assert_response :redirect
  end

  test 'denies #create if not global admin' do
    @user.update(global_admin: false)
    sign_in(@user)
    post admin_subdomains_url
    assert flash.alert
    assert_response :redirect
  end

  test 'allows #destroy if global admin' do
    sign_in(@user)
    assert_difference "Subdomain.all.size", -1 do
      delete admin_subdomain_url(id: @restarone_subdomain.id)
    end
    assert_response :redirect
  end

  test 'allows #create if global admin & invites them to the subdomain' do
    sign_in(@user)
    name = 'foobar'
    assert_difference "Subdomain.all.size", +1 do
      payload = {
        subdomain: {
          name: name
        }
      }
      perform_enqueued_jobs do
        assert_changes "Devise::Mailer.deliveries.size" do
          assert_difference "Subdomain.count", +1 do
            post admin_subdomains_url, params: payload
            Apartment::Tenant.switch name do
              assert User.first
            end
          end
        end
      end
      
    end
  end

  test 'allows #create if global admin & invites them to the subdomain with permission to manage everything' do
    sign_in(@user)
    name = 'foobar'
    assert_difference "Subdomain.all.size", +1 do
      payload = {
        subdomain: {
          name: name
        }
      }
      perform_enqueued_jobs do
        assert_changes "Devise::Mailer.deliveries.size" do
          assert_difference "Subdomain.count", +1 do
            post admin_subdomains_url, params: payload
            Apartment::Tenant.switch name do
              assert User.first
              assert User.first.can_manage_web
              assert User.first.can_manage_email
              assert User.first.can_manage_users
              assert User.first.can_manage_blog
              assert User.first.can_manage_api
            end
          end
        end
      end
      
    end
  end

  test 'denies #destroy if not global admin' do
    @user.update(global_admin: false)
    sign_in(@user)
    assert_no_difference "Subdomain.all.size" do
      delete admin_subdomain_url(id: @restarone_subdomain.id)
    end
    assert flash.alert
    assert_response :redirect
  end
end
