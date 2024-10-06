# frozen_string_literal: true

require 'solidus_starter_frontend_helper'

Spree::Order.class_eval do
  attr_accessor :did_transition
end

RSpec.describe 'Order transitions', type: :request, with_guest_session: true do
  # Regression test for https://github.com/spree/spree/issues/2004
  context "when a transition callback on first state" do
    let(:order) { create(:order, user: nil, store: store) }
    let!(:store) { create(:store) }

    before do
      first_state, = Spree::Order.checkout_steps.first
      Spree::Order.state_machine.after_transition to: first_state do |order|
        order.update(number: 'test')
      end
    end

    it "calls the transition callback" do
      expect(order.number).not_to eq 'test'
      order.line_items << create(:line_item)
      patch cart_path, params: { checkout: "checkout" }
      expect(order.reload.number).to eq 'test'
    end
  end
end
