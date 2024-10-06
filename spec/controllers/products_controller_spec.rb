# frozen_string_literal: true

require 'solidus_starter_frontend_helper'

RSpec.describe ProductsController, type: :controller do
  let!(:product) { create(:product, available_on: 1.year.from_now) }
  let!(:user)    { build(:user, spree_api_key: 'fake') }

  it 'allows admins to view non-active products' do
    allow(controller).to receive(:spree_current_user) { user }
    allow(user).to receive(:has_spree_role?) { true }
    get :show, params: { id: product.to_param }
    expect(response.status).to eq(200)
  end

  it 'cannot view non-active products' do
    allow(controller).to receive(:spree_current_user) { user }
    allow(user).to receive(:has_spree_role?) { false }

    expect {
      get :show, params: { id: product.to_param }
    }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
