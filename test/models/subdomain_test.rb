require "test_helper"

class SubdomainTest < ActiveSupport::TestCase
  setup do
    @subdomain = subdomains(:public)
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

  test 'creates valid hostname' do
    Apartment::Tenant.switch('public') { Comfy::Cms::Site.destroy_all }
    Subdomain.unsafe_bootstrap_www_subdomain
    Apartment::Tenant.switch('public') do
      assert_equal Comfy::Cms::Site.last.hostname, 'www.lvh.me:5250'
      assert_equal Comfy::Cms::Page.last.url, '//www.lvh.me:5250/'
    end
  end
end
