# frozen_string_literal: true

class LinkToCartComponent < ViewComponent::Base
  delegate :current_order, :spree, to: :helpers

  def call
    link_to text.html_safe, edit_cart_path, class: "cart-info #{css_class}", title: 'Cart'
  end

  private

  def text
    empty_current_order? ? '' : "<div class='link-text'>#{current_order.item_count}</div>"
  end

  def css_class
    empty_current_order? ? 'empty' : 'full'
  end

  def empty_current_order?
    current_order.nil? || current_order.item_count.zero?
  end
end
