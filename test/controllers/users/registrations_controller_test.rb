require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do

    @user = users(:public)
    @public_subdomain = subdomains(:public)
    @restarone_subdomain = Subdomain.find_by(name: 'restarone').name
  end

  test "should allow create (within subdomain scope)" do
    email = 'test@tester.com'
    password = '123456'
    payload = {
      user: {
        email: email,
        password: password,
        password_confirmation: password
      }
    }
    Apartment::Tenant.switch(@public_subdomain.name) do
      assert_difference "User.all.reload.size", +1 do
        post user_registration_url(subdomain: @public_subdomain.name), params: payload
        assert_response :redirect
        assert_select "div#error_explanation", { count: 0 }
        refute @controller.view_assigns['user'].errors.present?
      end
    end

    Apartment::Tenant.switch(@restarone_subdomain) do
      assert_difference "User.all.reload.size", +1 do
        post user_registration_url(subdomain: @restarone_subdomain), params: payload
        assert_response :redirect
        assert_select "div#error_explanation", { count: 0 }
        refute @controller.view_assigns['user'].errors.present?
      end
    end
  end

  test "should deny create (within subdomain scope) by showing validation-erros" do
    email = ''
    password = ''
    payload = {
      user: {
        email: email,
        password: password,
        password_confirmation: password
      }
    }
    Apartment::Tenant.switch(@public_subdomain.name) do
      assert_no_difference "User.count" do
        post user_registration_url(subdomain: @public_subdomain.name), params: payload

        assert_select "div#error_explanation"
        assert @controller.view_assigns['user'].errors.present?
      end
    end

    Apartment::Tenant.switch(@restarone_subdomain) do
      assert_no_difference "User.count" do
        post user_registration_url(subdomain: @restarone_subdomain), params: payload

        assert_select "div#error_explanation"
        assert @controller.view_assigns['user'].errors.present?
      end
    end
  end

  test "should allow #new (within subdomain scope)" do
    get new_user_registration_url(subdomain: @public_subdomain.name)
    assert_response :success
  end

  test "should deny #new if user self signups are denied" do
    @public_subdomain.update(allow_user_self_signup: false)
    get new_user_registration_url(subdomain: @public_subdomain.name)
    assert_response :redirect
  end

  test 'unconfirmed login results in redirect to subdomain landing page (within subdomain scope)' do
    get new_user_session_url(subdomain: @public_subdomain.name)
    assert_response :success
    assert_template :new
    @user.update(confirmed_at: nil)
    post user_session_url(subdomain: @public_subdomain.name), params: {user: {email: @user.email, password: '123456'}}
    assert_response :redirect
    assert_equal flash.alert, "You have to confirm your email address before continuing."
  end

  test 'confirmed login results in redirect to comfy admin panel (within subdomain scope)' do
    get comfy_admin_cms_url(subdomain: @public_subdomain.name)
    assert_response :redirect
    email = 'hello-world@restarone.solutions'
    password = '123456'
    payload = {
      user: {
        email: email,
        password: password,
      }
    }
    post user_session_url(subdomain: @public_subdomain.name), params: payload
    assert_response :redirect
    assert_redirected_to comfy_admin_cms_url(subdomain: @public_subdomain.name)
  end

  test 'login to comfy admin panel (within subdomain scope)' do
    sign_in(@user)
    Apartment::Tenant.switch @public_subdomain.name do
      get comfy_admin_cms_url(subdomain: @public_subdomain.name)
      assert_redirected_to comfy_admin_cms_site_pages_path(subdomain: @restarone_subdomain, site_id: Comfy::Cms::Site.first.id)
    end
  end

  test "should allow sign up at subdomain scope" do
    email = 'test1@tester.com'
    password = '123456'
    payload = {
      user: {
        email: email,
        password: password,
        password_confirmation: password
      }
    }
    assert_changes "Devise.mailer.deliveries.size" do          
      assert_changes "User.all.size", +1 do
        post user_registration_url(subdomain: @public_subdomain.name), params: payload
        assert_response :redirect
        assert_redirected_to root_url(subdomain: @public_subdomain.name)
        latest_user = User.last
        assert latest_user.email == email
        refute latest_user.global_admin
        refute latest_user.can_manage_web
        refute latest_user.can_manage_email
        refute latest_user.can_manage_users
        refute latest_user.can_manage_blog
        assert_equal flash.notice, "A message with a confirmation link has been sent to your email address. Please follow the link to activate your account."
      end
    end
  end

  test "should allow sign up at subdomain scope be notified " do
    layout = Comfy::Cms::Site.first.layouts.create(
      label: 'default',
      identifier: 'default',
      content: "{{cms:wysiwyg content}}",
      app_layout: 'website'
    )
    page = layout.pages.create(
      site_id: Comfy::Cms::Site.first.id,
      label: 'foo',
      slug: 'foo'
    )
    after_path = '/foo'
    @public_subdomain.update(after_sign_up_path: after_path)
    email = 'test1@tester.com'
    password = '123456'
    payload = {
      user: {
        email: email,
        password: password,
        password_confirmation: password
      }
    }
    post user_registration_url, params: payload
    assert_redirected_to after_path
  end


  test "should not allow sign up at subdomain scope if user self signup is disabled" do
    email = 'test1@tester.com'
    password = '123456'
    payload = {
      user: {
        email: email,
        password: password,
        password_confirmation: password
      }
    }
    @public_subdomain.update(allow_user_self_signup: false)
    assert_no_difference "Devise.mailer.deliveries.size" do          
      assert_no_difference "User.all.size" do
        post user_registration_url(subdomain: @public_subdomain.name), params: payload
        assert_response :redirect
      end
    end
  end

  test 'get #edit' do
    sign_in(@user)
    get edit_user_registration_url
    assert_response :success
  end

  test 'should allow #update if user provides current password with no validation errors' do
    payload = {
      user: {
        name: 'foo',
        current_password: '123456'
      }
    }
    assert_changes "@user.reload.name" do
      sign_in(@user)
      patch user_registration_url, params: payload
    end

    refute @controller.view_assigns['user'].errors.present?
  end

  test 'should deny #update if user does not provide current password with validation-error' do
    payload = {
      user: {
        name: 'foo',
      }
    }
    assert_no_changes "@user.reload.name" do
      sign_in(@user)
      patch user_registration_url, params: payload
    end

    assert @controller.view_assigns['user'].errors.present?
  end

  test 'should deny #update if user provides wrong current password and mismatched new-password  with validation-error' do
    payload = {
      user: {
        name: 'foo',
        current_password: 'sdkalfj',
        password: 'dkslafj',
        password_confirmation: 'sdafjlkj'
      }
    }
    assert_no_changes "@user.reload.name" do
      sign_in(@user)
      patch user_registration_url, params: payload
    end

    assert @controller.view_assigns['user'].errors.present?
  end

  test 'should allow #update_password without otp if enable_2fa is set to false' do
    Subdomain.current.update(enable_2fa: false)
    payload = {
      user: {
        current_password: '123456',
        password: '111111',
        password_confirmation: '111111'
      }
    }
    assert_changes "@user.reload.encrypted_password" do
      sign_in(@user)
      put user_registration_url, params: payload
    end
    
    assert_template 'shared/redirect.js.erb'
    refute @controller.view_assigns['user'].errors.present?

  end

  test 'should deny #update_password without otp if enable_2fa is set to true' do
    Subdomain.current.update(enable_2fa: true)
    payload = {
      user: {
        current_password: '123456',
        password: '111111',
        password_confirmation: '111111'
      }
    }
    sign_in(@user)
    put user_registration_url, params: payload
    assert_template 'users/shared/otp_visible.js.erb'
    payload = {
      user: {
        current_password: '123456',
        password: '111111',
        password_confirmation: '111111'
      }
    } 
    #shouldn't update password without otp
    assert_no_changes "@user.reload.encrypted_password" do
      put user_registration_url, params: payload
    end
    assert_match 'OTP Required', response.body
  end

  test 'should deny #update_password with invalid otp if enable_2fa is set to true' do
    Subdomain.current.update(enable_2fa: true)
    payload = {
      user: {
        current_password: '123456',
        password: '111111',
        password_confirmation: '111111'
      }
    }
    sign_in(@user)
    put user_registration_url, params: payload
    assert_template 'users/shared/otp_visible.js.erb'
    payload = {
      user: {
        current_password: '123456',
        password: '111111',
        password_confirmation: '111111',
        otp_attempt: '123123',
      }
    } 
    #shouldn't update password without otp
    assert_no_changes "@user.reload.encrypted_password" do
      put user_registration_url, params: payload
    end
    assert_match 'Invalid two-factor code.', response.body
  end

  test "shouldn't allow #update with invalid password" do
    Subdomain.current.update(enable_2fa: true)
    payload = {
      user: {
        current_password: '123123',
        password: '111111',
        password_confirmation: '111111'
      }
    }
    sign_in(@user)
    put user_registration_url, params: payload
    assert_template 'users/shared/error.js.erb'
  end


  test 'should allow #update with otp if enable_2fa is set to true' do
    Subdomain.current.update(enable_2fa: true)
    payload = {
      user: {
        current_password: '123456',
        password: '111111',
        password_confirmation: '111111'
      }
    }
    sign_in(@user)
    put user_registration_url, params: payload
    assert_template 'users/shared/otp_visible.js.erb'
    payload = {
      user: {
        current_password: '123456',
        password: '111111',
        password_confirmation: '111111',
        otp_attempt: @user.reload.current_otp
      }
    }
    assert_changes "@user.reload.encrypted_password" do
      put user_registration_url, params: payload
    end
    assert_template 'shared/redirect.js.erb'

    refute @controller.view_assigns['user'].errors.present?

  end


  test 'should resend_otp to user if resend otp button clicked' do
    Subdomain.current.update(enable_2fa: true)
    payload = {
      user: {
        current_password: '123456',
        password: '111111',
        password_confirmation: '111111'
      }
    }
    sign_in(@user)

    perform_enqueued_jobs do
      put user_registration_url, params: payload
    end
    assert_template 'users/shared/otp_visible.js.erb'
    mail_otp = UserMailer.deliveries.last.body.to_s.split(":").pop.strip();
    prev_otp = @user.reload.current_otp
    assert_equal mail_otp, prev_otp

    #resending otp
    perform_enqueued_jobs do
      get resend_otp_url
    end
    new_mail_otp = UserMailer.deliveries.last.body.to_s.split(":").pop.strip();
    new_otp = @user.reload.current_otp
    assert_equal new_mail_otp, new_otp
  end

  test 'deny #destroy' do
    assert_no_difference "User.all.size" do
      sign_in(@user)
      delete user_registration_url
      assert_response :redirect
    end
  end

  test 'should reset the otp_user_id for session in initial render' do
    get edit_user_registration_path
    assert_nil session[:otp_user_id]
  end
end
