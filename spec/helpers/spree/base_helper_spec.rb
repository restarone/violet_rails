# frozen_string_literal: true

require 'solidus_starter_frontend_helper'

RSpec.describe Spree::BaseHelper, type: :helper do
  # Regression test for https://github.com/spree/spree/issues/2759
  it "nested_taxons_path works with a Taxon object" do
    taxon = create(:taxon, name: "iphone")
    expect(nested_taxons_path(taxon)).to eq("/t/iphone")
  end
end
