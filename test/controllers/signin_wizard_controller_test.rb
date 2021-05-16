require "test_helper"

class SigninWizardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @subdomain = subdomains(:public)
  end


  test "redirects to subdomain URL after #create" do
    payload = {
      subdomain_request: {
        subdomain_name: @subdomain.name
      }
    }
    patch signin_wizard_path(id: 'update'), params: payload
    assert_response :redirect
  end

  test "redirects to #set_subdomain" do
    get signin_wizard_index_path
    assert_response :redirect
    follow_redirect!
    assert_template 'set_subdomain'
  end
end
