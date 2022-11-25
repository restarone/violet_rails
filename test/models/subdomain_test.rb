require "test_helper"

class SubdomainTest < ActiveSupport::TestCase
  setup do
    Sidekiq::Testing.fake!
    @subdomain = subdomains(:public)
  end

  test "can be created" do
    subdomain = Subdomain.new(name: "test")
    assert subdomain.save
  end

  test "uniqness" do
    duplicate = Subdomain.new(
      name: @subdomain.name
    )
    refute duplicate.valid?
  end

  test 'full host' do
    assert @subdomain.hostname
  end

  test 'hostname when name is not ROOT_DOMAIN_NAME' do
    ENV['APP_HOST']="lvh.me:5250"
    subdomain = Subdomain.new(name: "test")
    assert_equal 'test.lvh.me:5250', subdomain.hostname
  end

  test 'hostname when name is ROOT_DOMAIN_NAME' do
    ENV['APP_HOST']="lvh.me:5250"
    subdomain = Subdomain.new(name: Subdomain::ROOT_DOMAIN_NAME)
    assert_equal 'lvh.me:5250', subdomain.hostname
  end

  test 'downcases name' do
    name = 'Capitalized'
    subdomain = Subdomain.new(
      name: name
    )
    assert subdomain.valid?
    subdomain.save
    assert_equal name.downcase, subdomain.name
  end

  test 'sums storage usage' do
    assert @subdomain.storage_used < Subdomain::MAXIMUM_STORAGED_ALLOWANCE
    assert @subdomain.has_enough_storage?
  end

  test 'does not allow attachments if out of storage' do
    # enforced by initializer: config/initializers/active_storge.rb
    Subdomain.any_instance.stubs(:storage_used).returns(Subdomain::MAXIMUM_STORAGED_ALLOWANCE + 2)
    refute @subdomain.has_enough_storage?
    Apartment::Tenant.switch @subdomain.name do
      blob =  ActiveStorage::Blob.create(
        key: '123456',
        filename: 'file.txt',
        service_name: 'local',
        byte_size: 300,
        checksum: '123456asd'
      )
      attachment = ActiveStorage::Attachment.new(
        blob_id: blob.id,
        name: @subdomain.class,
        record_type: @subdomain.class,
        record_id: @subdomain.id
      )
      refute attachment.save
      assert_equal attachment.errors.full_messages.to_sentence, 'Subdomain out of storage'
    end
  end

  test 'does not allow destroy of root subdomain' do
    # if subdomain named 'root' is destroyed, the domain apex (also the www) will page will crash
    name = 'root'
    subdomain = Subdomain.new(
      name: name
    )
    assert subdomain.save
    begin
      subdomain.destroy
    rescue RuntimeError => e
      assert e
    else
      raise "error not raised when root domain was destroyed. This is a regression"
    end
    assert Subdomain.find_by(name: 'restarone').destroy
  end

  test 'sends analytics report if analytics_report_frequency is updated' do
    User.first.update(deliver_analytics_report: true)
    recipients = User.where(deliver_analytics_report: true)
    assert_difference "UserMailer.deliveries.size", +recipients.size do
      perform_enqueued_jobs do
        @subdomain.update(analytics_report_frequency: '1.week')
      end
    end
  end

  test 'does not sends analytics report if analytics_report_frequency is updated to never' do
    User.first.update(deliver_analytics_report: true)
    recipients = User.where(deliver_analytics_report: true)
    assert_no_difference "UserMailer.deliveries.size", +recipients.size do
      perform_enqueued_jobs do
        @subdomain.update(analytics_report_frequency: 'never')
      end
    end
  end

  test 'creates proper hostname' do
    ENV['APP_HOST']="lvh.me:5250"
    Apartment::Tenant.switch('public') { Comfy::Cms::Site.destroy_all }
    Subdomain.unsafe_bootstrap_www_subdomain
    Apartment::Tenant.switch('public') do
      assert_equal Comfy::Cms::Site.last.hostname, ENV['APP_HOST']
      assert_equal Comfy::Cms::Page.last.url, "//#{ENV['APP_HOST']}/"
    end
  end

  test "does not perform plugin: subdomain/subdomain_events routine if not enabled" do
    @subdomain.update!(api_plugin_events_enabled: false)
    message_thread = message_threads(:public)
    message = message_thread.messages.create!(content: "Hello")
    service = ApiNamespace::Plugin::V1::SubdomainEventsService.new(message)
    assert_no_difference "ApiResource.count" do      
      service.track_event
      Sidekiq::Worker.drain_all
    end
  end

  test "performs plugin: subdomain/subdomain_events routine if enabled" do
    @subdomain.update!(api_plugin_events_enabled: true)
    message_thread = message_threads(:public)
    message = message_thread.messages.create!(content: "Hello")
    service = ApiNamespace::Plugin::V1::SubdomainEventsService.new(message)
    assert_difference "ApiResource.count", +1 do      
      service.track_event
      Sidekiq::Worker.drain_all
    end
  end

  test "expect Otp required to be true if 2fa is enabled" do
    @subdomain.update!(enable_2fa: true)
    User.all.each do |user|
      assert user.otp_required_for_login 
      assert user.otp_secret 
    end
  end

  test "expect Otp required to be false if 2fa is disabled" do
    @subdomain.update!(enable_2fa: false)
    User.all.each do |user|
      refute user.otp_required_for_login
      refute user.otp_secret 
    end
  end

  test "expect new User's default 2fa to be true if enable_2fa is already true" do
    @subdomain.update!(enable_2fa: true)
    new_user = User.create(email: 'abc@test.com', password: '123456')
    assert new_user.otp_required_for_login
    assert new_user.otp_secret 
  end

  test "email_notification_strategy should not accept anything except user_email or system_email" do  
    exception = assert_raises(Exception) { 
      duplicate = Subdomain.new(
        email_notification_strategy: 'restarone_email'
      )
     }
    assert_equal( "'restarone_email' is not a valid email_notification_strategy", exception.message )
  end

  test 'subdomain to be enabled if the script is run in console' do
    ENV['APP_HOST']="lvh.me:5250"
    subdomain1 = Subdomain.new(name: "test")
    subdomain2 = Subdomain.new(name: "demo")
    Subdomain.all.each do |subdomain| 
      Apartment::Tenant.switch subdomain.name do
        new_user1 = User.create(email: 'abc@test.com', password: '123456')
        new_user2 = User.create(email: 'xyz@test.com', password: '111111')
        new_user3 = User.create(email: 'mno@test.com', password: '456789')
      end
    end
    Subdomain.all.each{ |subdomain| subdomain.update(enable_2fa: true)}
    Subdomain.all.each do |subdomain| 
      assert subdomain.enable_2fa
      Apartment::Tenant.switch subdomain.name do
        User.all.each do |user|
          assert user.otp_required_for_login 
          assert user.otp_secret 
        end
      end
    end
  end
end
