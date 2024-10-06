# frozen_string_literal: true
# This migration comes from spree (originally 20201127212108)

class AddTypeBeforeRemovalToSpreePaymentMethods < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_payment_methods, :type_before_removal, :string
  end
end
