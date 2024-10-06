# frozen_string_literal: true

require 'solidus_starter_frontend_helper'

RSpec.describe 'Cart', type: :system, inaccessible: true do
  before { create(:store) }

  it "shows cart icon on non-cart pages" do
    visit root_path
    expect(page).to have_selector("#link-to-cart a", visible: true)
  end

  it "prevents double clicking the remove button on cart", js: true do
    @product = create(:product, name: "RoR Mug")

    visit root_path
    click_link "RoR Mug"
    click_button "add-to-cart-button"

    # prevent form submit to verify button is disabled
    page.execute_script("document.getElementById('update-cart').onsubmit = function(){return false;}")

    expect(page).not_to have_selector('button#update-button[disabled]')
    find('.delete').click
    expect(page).to have_selector('button#update-button[disabled]')
  end

  it 'allows you to remove an item from the cart', js: true do
    create(:product, name: "RoR Mug")
    visit root_path
    click_link "RoR Mug"
    click_button "add-to-cart-button"
    find('.delete').click
    expect(page).not_to have_content("Line items quantity must be an integer")
    expect(page).not_to have_content("RoR Mug")
    expect(page).to have_content("Your cart is empty")

    within "#link-to-cart" do
      expect(page.text).to eq('')
    end
  end

  it 'allows you to empty the cart', js: true do
    create(:product, name: "RoR Mug")
    visit root_path
    click_link "RoR Mug"
    click_button "add-to-cart-button"

    expect(page).to have_content("RoR Mug")
    click_on "Empty Cart"
    expect(page).to have_content("Your cart is empty")

    within "#link-to-cart" do
      expect(page.text).to eq('')
    end
  end

  # regression for https://github.com/spree/spree/issues/2276
  context "product contains variants but no option values" do
    let(:variant) { create(:variant) }
    let(:product) { variant.product }

    before { variant.option_values.destroy_all }

    it "still adds product to cart", inaccessible: true do
      visit product_path(product)
      click_button "add-to-cart-button"

      visit edit_cart_path
      expect(page).to have_content(product.name)
    end
  end
end
