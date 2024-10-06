# frozen_string_literal: true

require 'solidus_starter_frontend_helper'

RSpec.describe 'Visiting Products', type: :system, inaccessible: true do
  include SystemHelpers

  include_context "custom products"

  let(:store_name) do
    ((first_store = Spree::Store.first) && first_store.name).to_s
  end

  before(:each) do
    visit root_path
  end

  it 'should be able to show the shopping cart after adding a product to it' do
    click_link 'Ruby on Rails Ringer T-Shirt'
    expect(page).to have_content('$19.99')

    click_button 'add-to-cart-button'
    expect(page).to have_content('Shopping Cart')
  end

  # Regression spec for Spree [PR#7442](https://github.com/spree/spree/pull/7442)
  context 'when generating product links' do
    let(:product) { Spree::Product.available.first }

    it 'should not use the *_url helper to generate the product links' do
      visit root_path
      expect(page).not_to have_xpath(".//a[@href='#{product_url(product, host: current_host)}']")
    end

    it 'should use *_path helper to generate the product links' do
     visit root_path
     expect(page).to have_xpath(".//a[@href='#{product_path(product)}']")
    end
  end

  describe 'meta tags and title' do
    let(:jersey) { Spree::Product.find_by(name: 'Ruby on Rails Baseball Jersey') }
    let(:metas) do
      {
        meta_description: 'Brand new Ruby on Rails Jersey',
        meta_title: 'Ruby on Rails Baseball Jersey Buy High Quality Geek Apparel',
        meta_keywords: 'ror, jersey, ruby'
      }
    end

    it 'should return the correct title when displaying a single product' do
      click_link jersey.name
      expect(page).to have_title('Ruby on Rails Baseball Jersey - ' + store_name)
      within('h1.product-header__title') do
        expect(page).to have_content('Ruby on Rails Baseball Jersey')
      end
    end

    it 'displays metas' do
      jersey.update metas
      click_link jersey.name
      expect(page).to have_meta(:description, 'Brand new Ruby on Rails Jersey')
      expect(page).to have_meta(:keywords, 'ror, jersey, ruby')
    end

    it 'displays title if set' do
      jersey.update metas
      click_link jersey.name
      expect(page).to have_title('Ruby on Rails Baseball Jersey Buy High Quality Geek Apparel')
    end

    it "doesn't use meta_title as heading on page" do
      jersey.update metas
      click_link jersey.name
      within('h1') do
        expect(page).to have_content(jersey.name)
        expect(page).not_to have_content(jersey.meta_title)
      end
    end

    it 'uses product name in title when meta_title set to empty string' do
      jersey.update meta_title: ''
      click_link jersey.name
      expect(page).to have_title('Ruby on Rails Baseball Jersey - ' + store_name)
    end
  end

  describe 'schema.org markup' do
    let(:product) { Spree::Product.available.first }

    it 'has correct schema.org/Offer attributes' do
      expect(page).to have_css("#product_#{product.id} [itemprop='price'][content='19.99']")
      expect(page).to have_css("#product_#{product.id} [itemprop='priceCurrency'][content='USD']")
      click_link product.name
      expect(page).to have_css("[itemprop='price'][content='19.99']")
      expect(page).to have_css("[itemprop='priceCurrency'][content='USD']")
    end
  end

  context 'using Russian Rubles as a currency' do
    before do
      stub_spree_preferences(currency: 'RUB')
    end

    let!(:product) do
      product = Spree::Product.find_by(name: 'Ruby on Rails Ringer T-Shirt')
      product.price = 19.99
      product.tap(&:save)
    end

    # Regression tests for https://github.com/spree/spree/issues/2737
    context 'uses руб as the currency symbol' do
      it 'on products page' do
        visit root_path
        within("#product_#{product.id}") do
          within('.price') do
            expect(page).to have_content('19.99 ₽')
          end
        end
      end

      it 'on product page' do
        visit product_path(product)
        within("[data-js='price']") do
          expect(page).to have_content('19.99 ₽')
        end
      end

      it "when on the 'address' state of the cart", js: true do
        visit product_path(product)
        click_button 'Add To Cart'
        checkout_as_guest

        within('#item-total') do
          expect(page).to have_content('19.99 ₽')
        end
      end
    end
  end

  it 'should be able to search for a product' do
    fill_in 'keywords', with: 'shirt'
    click_button 'Search'

    expect(page.all('ul.products-grid li').size).to eq(1)
  end

  context 'a product with variants' do
    let(:product) do
      Spree::Product.find_by(name: 'Ruby on Rails Baseball Jersey')
    end
    let(:option_value) { create(:option_value) }
    let!(:variant) { product.variants.create!(price: 5.59) }

    before do
      # Need to have two images to trigger the error
      image = File.open(
        File.join(Spree::Core::Engine.root, "lib", "spree", "testing_support", "fixtures", "blank.jpg")
      )
      product.images.create!(attachment: image)
      product.images.create!(attachment: image)

      product.option_types << option_value.option_type
      variant.option_values << option_value
    end

    it 'displays price of first variant listed', js: true do
      click_link product.name

      within("#product-price") do
        expect(page).to have_content variant.price
        expect(page).not_to have_content I18n.t('spree.out_of_stock')
      end
    end

    it "doesn't display out of stock for master product" do
      product.master.stock_items.update_all count_on_hand: 0, backorderable: false

      click_link product.name
      within("[data-js='price']") do
        expect(page).not_to have_content I18n.t('spree.out_of_stock')
      end
    end
  end

  context 'a product with variants, images only for the variants' do
    let(:product) do
      Spree::Product.find_by(name: 'Ruby on Rails Baseball Jersey')
    end

    before do
      image = File.open(
        File.join(Spree::Core::Engine.root, "lib", "spree", "testing_support", "fixtures", "blank.jpg")
      )
      v1 = product.variants.create!(price: 9.99)
      v2 = product.variants.create!(price: 10.99)
      v1.images.create!(attachment: image)
      v2.images.create!(attachment: image)
    end

    it 'should not display no image available' do
      visit root_path
      expect(page).to have_xpath("//img[contains(@src,'blank')]")
    end
  end

  it 'should be able to hide products without price' do
    expect(page.all('ul.products-grid li').size).to eq(9)
    stub_spree_preferences(show_products_without_price: false)
    stub_spree_preferences(currency: 'CAN')
    visit root_path
    expect(page.all('ul.products-grid li').size).to eq(0)
  end

  it 'can filter products' do
    visit products_path

    within(:css, '.taxonomies') { click_link 'Ruby on Rails' }
    check 'Price_Range__15.00_-__18.00'
    within(:css, '#sidebar_products_search') { click_button 'Search' }

    product_names = page.all('ul.products-grid li a').map(&:text).flatten.reject(&:blank?).sort

    expect(product_names)
      .to eq(['Ruby on Rails Mug', 'Ruby on Rails Stein', 'Ruby on Rails Tote'])
  end

  it 'should be able to put a product without a description in the cart' do
    product = FactoryBot.create(:base_product, description: nil, name: 'Sample', price: '19.99')
    visit product_path(product)
    expect(page).to have_content 'This product has no description'
    click_button 'add-to-cart-button'
    expect(page).to have_content 'This product has no description'
  end

  it "shouldn't be able to put a product without a current price in the cart" do
    product = FactoryBot.create(:base_product, description: nil, name: 'Sample', price: '19.99')
    stub_spree_preferences(currency: 'CAN')
    stub_spree_preferences(show_products_without_price: true)
    visit product_path(product)
    expect(page).to have_content 'This product is not available in the selected currency'
    expect(page).not_to have_content 'add-to-cart-button'
  end

  it 'should be able to list products without a price' do
    product = FactoryBot.create(:base_product, description: nil, name: 'Sample', price: '19.99')
    stub_spree_preferences(currency: 'CAN')
    stub_spree_preferences(show_products_without_price: true)
    visit products_path
    expect(page).to have_content(product.name)
  end

  it 'should return the correct title when displaying a single product' do
    product = Spree::Product.find_by(name: 'Ruby on Rails Baseball Jersey')
    click_link product.name

    within('h1.product-header__title') do
      expect(page).to have_content('Ruby on Rails Baseball Jersey')
    end
  end
end
