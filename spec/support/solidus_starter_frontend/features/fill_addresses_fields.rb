# frozen_string_literal: true

module FillAddressFields
  def fill_addresses_fields_with(address)
    fields = %w[
      address1
      city
      zipcode
      phone
    ]
    fields += if SolidusSupport.combined_first_and_last_name_in_address?
      %w[name]
    else
      %w[firstname lastname]
    end

    fields.each do |field|
      fill_in "order_bill_address_attributes_#{field}", with: address.send(field).to_s
    end
    select 'United States', from: "order_bill_address_attributes_country_id"
    select address.state.name.to_s, from: "order_bill_address_attributes_state_id"

    check 'order_use_billing'
  end
end

RSpec.configure do |config|
  config.include FillAddressFields, type: :system
end
