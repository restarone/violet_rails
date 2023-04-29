require "test_helper"

class Users::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:public)
    @public_subdomain = @user.subdomain
    @restarone_subdomain = Subdomain.find_by(name: 'restarone')
    Apartment::Tenant.switch @restarone_subdomain.name do
      @restarone_user = User.find_by(email: 'contact@restarone.com')
    end
  end

  test 'should allow #login without otp if enable_2fa is set to false' do
    Subdomain.current.update(enable_2fa: false)
    @user.update(global_admin: true)
    payload = {
      user: {
        email: @user.email,
        password: '123456'
      }
    }
    post user_session_url, params: payload
    assert_redirected_to admin_subdomain_requests_url
  end

  test 'should deny #login with wrong otp if enable_2fa is set to true' do
    Subdomain.current.update(enable_2fa: true)
    payload = {
      user: {
        email: @user.email,
        password: '123456',
      }
    }
    post user_session_url, params: payload
    assert_redirected_to users_sign_in_otp_url
    payload = {
      user: {
        otp_attempt: 'invalid'
      }
    }
    post users_sign_in_otp_url, params: payload
    assert_equal 'Failed to authenticate your code', flash[:danger]
    assert_redirected_to users_sign_in_otp_url
  end

  test "should allow #login without otp if enable_2fa is set to true and current_sign_in_ip is equal to user's current ip" do
    Subdomain.current.update(enable_2fa: true)
    @user.update(global_admin: true, current_sign_in_ip: '172.18.1.0')
    payload = {
      user: {
        email: @user.email,
        password: '123456',
      }
    }
    post user_session_url, params: payload, env: { "REMOTE_ADDR": "172.18.1.0" }
    assert_redirected_to admin_subdomain_requests_url
  end

  test "should deny #login without otp if enable_2fa is set to true and current_sign_in_ip is not equal to user's current ip" do
    Subdomain.current.update(enable_2fa: true)
    @user.update(current_sign_in_ip: '172.18.1.0')
    payload = {
      user: {
        email: @user.email,
        password: '123456',
      }
    }
    post user_session_url, params: payload, env: { "REMOTE_ADDR": "172.20.1.1" }
    assert_redirected_to users_sign_in_otp_url

    payload = {
      user: {
        email: @user.email,
        password: '123456',
      }
    }
    post users_sign_in_otp_url, params: payload, env: { "REMOTE_ADDR": "172.20.1.1" }
    assert_equal 'Failed to authenticate your code', flash[:danger]
    assert_redirected_to users_sign_in_otp_url
  end

  test "should allow #login with otp if enable_2fa is set to true and current_sign_in_ip is not equal to user's current ip" do
    Subdomain.current.update(enable_2fa: true)
    # successful login and displaying 2fa page
    @user.update(global_admin: true, current_sign_in_ip: '172.18.1.0')
    payload = {
      user: {
        email: @user.email,
        password: '123456',
      },
    }
    post user_session_url, params: payload, env: { "REMOTE_ADDR": "172.18.1.1" }
    assert_redirected_to users_sign_in_otp_url

    # valid otp and redirection to admin subdomain page
    payload = {
      user: {
        otp_attempt: @user.reload.current_otp,
      },
      session: { otp_user_id: @user.id } 
    }
    post users_sign_in_otp_url, params: payload, env: { "REMOTE_ADDR": "172.18.1.1" }
    assert_redirected_to admin_subdomain_requests_url
    follow_redirect!
    assert_template :index
  end

  test 'should reset the otp_user_id for session in initial render' do
    get new_user_session_path
    assert_nil session[:otp_user_id]
  end
end