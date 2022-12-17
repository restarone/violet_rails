require "test_helper"

class ActiveStorage::DiskControllerTest < ActionDispatch::IntegrationTest
  setup do
    @subdomain = Subdomain.current
    site = Comfy::Cms::Site.first
    @file = site.files.create(
      label:        "test",
      description:  "test file",
      file:         fixture_file_upload("fixture_image.png", "image/jpeg")
    )
  end

  test 'should retain ahoy cookies if tracking is enabled and cookies are accepted' do
    @subdomain.update(tracking_enabled: true)
    get rails_blob_url(@file.attachment), headers: {"HTTP_COOKIE" => "cookies_accepted=true;"}
    
    assert cookies[:ahoy_visit]
    assert cookies[:ahoy_visitor]
  end

  test 'should not retain ahoy cookies if tracking is enabled and cookies are declined' do
    @subdomain.update(tracking_enabled: true)
    get rails_blob_url(@file.attachment), headers: {"HTTP_COOKIE" => "cookies_accepted=false;"}
    
    refute cookies[:ahoy_visit]
    refute cookies[:ahoy_visitor]
  end

  test 'should not retain ahoy cookies if tracking is disabled' do
    @subdomain.update(tracking_enabled: false)
    get rails_blob_url(@file.attachment)
    
    refute cookies[:ahoy_visit]
    refute cookies[:ahoy_visitor]
  end
end
