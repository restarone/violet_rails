# frozen_string_literal: true

require 'truncate_html'
require 'app/helpers/truncate_html_helper'

module OrdersHelper
  include TruncateHtmlHelper

  def truncated_product_description(product)
    truncate_html(raw(product.description))
  end

  def order_just_completed?(order)
    flash[:order_completed] && order.present?
  end
end
