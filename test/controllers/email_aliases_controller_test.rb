require "test_helper"

class EmailAliasesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @restarone_subdomain = Subdomain.find_by(name: 'restarone')
    @user = users(:public)
    @domain = @user.subdomain
    @user.update(can_manage_email: true)
    sign_in(@user)
    Apartment::Tenant.switch @restarone_subdomain.name do
      @other_user = User.first
      @other_user.update(can_manage_email: true)
    end
  end
  
  test 'allows #index' do
    get email_aliases_url(subdomain: @domain)
    assert_response :success
    assert_template :index
  end

  test 'denies #index if not permissioned' do
    @user.update(can_manage_email: false)
    get email_aliases_url(subdomain: @domain)
    assert_response :redirect
    assert_redirected_to admin_users_url(subdomain: @domain)
  end

  test 'denies #index if not associated with the subdomain' do
    sign_out(@user)
    sign_in(@other_user)
    get email_aliases_url(subdomain: @domain)
    assert_response :redirect
  end

  test 'renders #new' do
    get new_email_alias_url(subdomain: @domain)
    assert_response :success
    assert_template :new
  end

  test 'allows #create' do
    payload = {
      email_alias: {
        name: 'foobar',
        user_id: @user.id
      }
    }
    assert_difference "EmailAlias.all.size", +1 do
      post email_aliases_url(subdomain: @domain), params: payload
      assert_response :redirect
      assert_redirected_to email_aliases_url(subdomain: @domain)
    end
    get email_aliases_url(subdomain: @domain)
    assert_response :success
  end
end
