require "test_helper"
require "rake"

class FillEmptyLocationEntriesTaks < ActiveSupport::TestCase
  setup do
    new_visit = Ahoy::Visit.create(ip: '101.33.22.0')
  end

  test 'populate location of a new created entry' do
    Rake::Task["ahoy:fill_empty_location_entries"].invoke

    assert_equal new_visit.country.nil?, false
    assert_equal new_visit.region.nil?, false
    assert_equal new_visit.city.nil?, false
  end
end