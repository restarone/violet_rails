require "solidus_starter_frontend_helper"

# I'm getting the "NameError Exception: uninitialized constant
# `#<Class:0x000056478b9a4100>::ActiveStorageAttachment`" in byebug unless I
# require spree/taxon.
require 'spree/taxon'

RSpec.describe BreadcrumbsComponent, type: :component do
  let(:request_url) { '/' }

  let(:breadcrumb_items) do
    page.all('a[itemprop=item]').map(&:text)
  end

  context 'when rendered' do
    before do
      allow(self.request).to receive(:path).and_return(request_url)

      render_inline(described_class.new(taxon))
    end

    context 'when the taxon is nil' do
      let(:taxon) { nil }

      it 'does not render any breadcrumb items' do
        expect(breadcrumb_items.size).to eq(0)
      end
    end

    context 'when the taxon is present' do
      let(:parent) { nil }
      let(:grandparent) { nil }
      let(:taxon) { create(:taxon, name: 'some taxon', parent: parent) }

      context 'when the current page is the root page' do
        let(:request_url) { '/' }

        it 'does not render any breadcrumb items' do
          expect(breadcrumb_items.size).to eq(0)
        end
      end

      context 'when the current page is not the root page' do
        let(:request_url) { '/products' }

        context 'when the taxon has no ancestors' do
          let(:parent) { nil }

          it 'renders a breadcrumb for the taxon' do
            expect(breadcrumb_items.size).to eq(3)
            expect(breadcrumb_items.last).to eq(taxon.name)
          end
        end

        context 'when the taxon has ancestors' do
          let(:grandparent) { create(:taxon, name: 'some grandparent', parent: nil) }
          let(:parent) { create(:taxon, name: 'some parent', parent: grandparent) }

          it 'renders a breadcrumb for the taxon and its ancestors' do
            expect(breadcrumb_items.size).to eq(5)
            expect(breadcrumb_items[-3]).to eq(grandparent.name)
            expect(breadcrumb_items[-2]).to eq(parent.name)
            expect(breadcrumb_items[-1]).to eq(taxon.name)
          end
        end
      end
    end
  end
end
