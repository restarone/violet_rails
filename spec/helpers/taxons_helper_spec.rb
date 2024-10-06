# frozen_string_literal: true

require 'solidus_starter_frontend_helper'

RSpec.describe TaxonsHelper, type: :helper do
  describe '#taxon_seo_url' do
    let(:taxon_permalink) { 'ruby-on-rails' }
    let(:taxon) { create(:taxon, permalink: taxon_permalink) }

    it 'is the nested taxons path for the taxon' do
      expect(taxon_seo_url(taxon)).to eq("/t/#{taxon_permalink}")
    end
  end
end
