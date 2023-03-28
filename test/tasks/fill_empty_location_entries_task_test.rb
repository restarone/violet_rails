require "test_helper"
require "rake"
require 'faker'

class FillEmptyLocationEntriesTaks < ActiveSupport::TestCase
  setup do
    @new_visit = Ahoy::Visit.create!(
      started_at: Time.now,
      ip: Faker::Internet.ip_v4_address, 
      os: 'GNU/Linux', 
      browser: 'Firefox', 
      device_type: 'Desktop', 
      user_agent: Faker::Internet.user_agent, 
      landing_page: 'http://localhost:5250/',
      visit_token: 'random_hash'
    )
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    Sidekiq::Testing.fake!
  end
  
  test 'populate location of a new created entry' do
    stub_request(:get, /http:\/\/ipinfo.io\/*/).to_return(status: 200, body: {
        "ip": "110.41.52.64",
        "hostname": "ecs-110-41-52-64.compute.hwclouds-dns.com",
        "city": "Guangzhou",
        "region": "Guangdong",
        "country": "CN",
        "loc": "23.1167,113.2500",
        "org": "AS55990 Huawei Cloud Service data center",
        "timezone": "Asia/Shanghai",
        "readme": "https://ipinfo.io/missingauth"
    }.to_json)

    refute @new_visit.country
    refute @new_visit.region
    refute @new_visit.city

    perform_enqueued_jobs do
      Rake::Task["ahoy:fill_empty_location_entries"].invoke
      Sidekiq::Worker.drain_all
    end

    @new_visit.reload

    assert_equal 'CN', @new_visit.country
    assert_equal 'Guangdong', @new_visit.region
    assert_equal 'Guangzhou', @new_visit.city
  end
end