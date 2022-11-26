require "test_helper"

class Users::InvitationsControllerTest < ActionDispatch::IntegrationTest
    setup do
        @user = users(:public)
        @public_subdomain = subdomains(:public)
        @restarone_subdomain = Subdomain.find_by(name: 'restarone').name
      end

      test 'should deny #accept_invitation with wrong otp if enable_2fa is set to true' do
        Subdomain.current.update(enable_2fa: true)

        invitee_email = 'invitee@example.org'
        
       @invitee =  User.invite!(email: invitee_email) do |u|
          u.invited_by = @user
        end
        payload = {
          user: {
            invitation_token: @invitee.raw_invitation_token,
            password: 'dkslafj',
            password_confirmation: 'dkslafj',
            otp_attempt: '123123',
          }
        }
        put user_invitation_url, params: payload
        assert_template 'users/shared/otp_visible.js.erb'

        payload = {
          user: {
            invitation_token: @invitee.raw_invitation_token,
            password: 'dkslafj',
            password_confirmation: 'dkslafj',
            otp_attempt: '123123',
          }
        }
        put user_invitation_url, params: payload
        assert_match 'Invalid two-factor code.', response.body
      end

      test 'should deny #accept_invitation without otp if enable_2fa is set to true' do
        Subdomain.current.update(enable_2fa: true)

        invitee_email = 'invitee@example.org'
        
       @invitee =  User.invite!(email: invitee_email) do |u|
          u.invited_by = @user
        end
        payload = {
          user: {
            invitation_token: @invitee.raw_invitation_token,
            password: 'dkslafj',
            password_confirmation: 'dkslafj',
          }
        }
        put user_invitation_url, params: payload
        assert_template 'users/shared/otp_visible.js.erb'

        payload = {
          user: {
            invitation_token: @invitee.raw_invitation_token,
            password: 'dkslafj',
            password_confirmation: 'dkslafj',
          }
        }
        put user_invitation_url, params: payload
        assert_match 'OTP Required', response.body
      end

      test 'should allow #accept_invitation without otp if enable_2fa is set to false' do
        Subdomain.current.update(enable_2fa: false)

        invitee_email = 'invitee@example.org'
        
       @invitee =  User.invite!(email: invitee_email) do |u|
          u.invited_by = @user
        end
        payload = {
          user: {
            invitation_token: @invitee.raw_invitation_token,
            password: '111111',
            password_confirmation: '111111',
          }
        }
        put user_invitation_url, params: payload
        assert_match root_url(subdomain: @public_subdomain.name), response.body
      end


      test 'should allow #accept_invitation with otp if enable_2fa is set to true' do
        Subdomain.current.update(enable_2fa: true)
        invitee_email = 'invitee@example.org'
        
        @invitee =  User.invite!(email: invitee_email) do |u|
          u.invited_by = @user
        end
        payload = {
          user: {
            invitation_token: @invitee.raw_invitation_token,
            password: '123456',
            password_confirmation: '123456',
          }
        }

        put user_invitation_url, params: payload

        assert_template 'users/shared/otp_visible.js.erb'
        payload = {
          user: {
            invitation_token: @invitee.raw_invitation_token,
            password: '123456',
            password_confirmation: '123456',
            otp_attempt: @invitee.reload.current_otp
          },
          session: { otp_user_id: @user.id } 
        }
        put user_invitation_url, params: payload
        assert_match root_url(subdomain: @public_subdomain.name), response.body
      end

      test 'should reset the otp_user_id for session in initial render' do
        get accept_user_invitation_path
        assert_nil session[:otp_user_id]
      end
end