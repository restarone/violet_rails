require "test_helper"

class SignupWizardControllerTest < ActionDispatch::IntegrationTest
  test "renders wizard #index (step 1)" do
    get signup_wizard_index_path
    assert_response :redirect
    follow_redirect!
    assert_template :scopes_of_service
  end

  test "submits steps" do
    payload = {
      subdomain_request: {
        requires_web: true,
        requires_blog: false,
        requires_forum: true, 
      }
    }
    assert_difference "SubdomainRequest.all.size", +1 do
      post signup_wizard_index_path(id: 'subdomain_name'), params: payload
      assert_response :redirect
      follow_redirect!
      assert_template :subdomain_name
    end
    subdomain_request = SubdomainRequest.last
    assert subdomain_request.requires_web
    refute subdomain_request.requires_blog
    assert subdomain_request.requires_forum
    payload = {
      subdomain_request: {
        subdomain_name: 'foobarbazquux'
      }
    }
    assert_changes "subdomain_request.reload.subdomain_name" do
      patch signup_wizard_path(id: 'subdomain_name', subdomain_request_id: subdomain_request.slug), params: payload
      assert_response :redirect
      follow_redirect!
      assert_template :sign_up
    end
    payload = {
      subdomain_request: {
        email: 'foo@bar.com'
      }
    }
    assert_changes "subdomain_request.reload.email" do
      patch signup_wizard_path(id: 'sign_up', subdomain_request_id: subdomain_request.slug), params: payload
      assert_response :redirect
      follow_redirect!
      assert_redirected_to root_url
      assert flash.notice
    end
  end
end
