# frozen_string_literal: true

require 'solidus_starter_frontend_helper'

RSpec.describe 'Switching currencies in backend', type: :system do
  before do
    create(:store)
    create(:base_product, name: "RoR Mug")
  end

  # Regression test for https://github.com/spree/spree/issues/2340
  it "does not cause current_order to become nil", inaccessible: true do
    visit root_path
    click_link "RoR Mug"
    click_button "Add To Cart"
    # Now that we have an order...
    stub_spree_preferences(currency: "AUD")
    visit root_path
  end
end
