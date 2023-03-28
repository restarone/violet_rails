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
      landing_page: 'http://localhost:5250/'
    )
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    Sidekiq::Testing.fake!
  end
  
  test 'populate location of a new created entry' do

    assert_equal @new_visit.country.nil?, true
    assert_equal @new_visit.region.nil?, true
    assert_equal @new_visit.city.nil?, true

    perform_enqueued_jobs do
      Rake::Task["ahoy:fill_empty_location_entries"].invoke
      Sidekiq::Worker.drain_all
    end

    sleep 2

    @new_visit.reload
    assert_equal @new_visit.country.nil?, false
    assert_equal @new_visit.region.nil?, false
    assert_equal @new_visit.city.nil?, false
  end
end