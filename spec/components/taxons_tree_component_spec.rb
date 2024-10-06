require "solidus_starter_frontend_helper"
require 'spree/taxon'

RSpec.describe TaxonsTreeComponent, type: :component do
  let(:taxon_without_descendants) { create(:taxon, children: []) }

  let(:taxon_with_descendants) do
    root = create(:taxon)

    children = [
      create(:taxon, name: 'child 1', parent: root),
      create(:taxon, name: 'child 2', parent: root)
    ]

    # child 1 grandchild
    create(:taxon, name: 'grandchild 1', parent: children[0])

    root
  end

  let(:title) { 'some_title' }
  let(:root_taxon) { taxon_with_descendants }
  let(:current_taxon) { nil }
  let(:max_level) { 1 }
  let(:base_class) { 'some_base_class' }

  let(:local_assigns) do
    {
      title: title,
      root_taxon: root_taxon,
      current_taxon: current_taxon,
      max_level: max_level,
      base_class: base_class
    }
  end

  context 'when rendered' do
    before do
      render_inline(described_class.new(**local_assigns))
    end

    describe 'concerning max_level and root_taxon' do
      context 'when the max level is less than 1' do
        let(:max_level) { 0 }

        it 'does not render any items' do
          expect(page.all('li')).to be_empty
        end
      end

      context 'when the max level is 1' do
        let(:max_level) { 1 }

        context 'when the root taxon has no descendants' do
          let(:root_taxon) { taxon_without_descendants }

          it 'does not render any items' do
            expect(page.all('li')).to be_empty
          end
        end

        context 'when the root taxon has descendants' do
          let(:root_taxon) { taxon_with_descendants }

          it "renders a list of the root taxon's children" do
            expect(page.all('li').map(&:text)).to match(['child 1', 'child 2'])
          end
        end
      end

      context 'when the max level is greater than 1' do
        let(:max_level) { 2 }

        context 'when the root taxon has no descendants' do
          let(:root_taxon) { taxon_without_descendants }

          it 'does not render any items' do
            expect(page.all('li')).to be_empty
          end
        end

        context 'when the root taxon has descendants' do
          let(:root_taxon) { taxon_with_descendants }

          it "renders a list of the root taxon's descendants" do
            # child 1's text includes the text of the grandchild 1.
            expect(page.all('li').map(&:text)).to match(['child 1grandchild 1', 'grandchild 1', 'child 2'])
          end
        end
      end
    end

    describe 'concerning current_taxon' do
      context 'when current_taxon is not provided' do
        let(:current_taxon) { nil }

        it 'does not mark any taxon as "current"' do
          expect(page).to have_no_css('li.current')
        end
      end

      context 'when current_taxon is provided' do
        context 'when current_taxon matches a descendant' do
          let(:current_taxon) { root_taxon.children.first }

          it 'marks the current taxon as "current"' do
            expect(page.find('li.current')).to have_text('child 1')
          end
        end

        context 'when current_taxon does not match any descendant' do
          let(:current_taxon) { create(:taxon) }

          it 'does not mark any taxon as "current"' do
            expect(page).to have_no_css('li.current')
          end
        end
      end
    end

    describe 'concerning base_class' do
      let(:title) { 'some_title' }
      let(:base_class) { 'some_base_class' }

      it 'uses the base class as prefix for the list and title classes' do
        aggregate_failures do
          expect(page).to have_css('h6.some_base_class__title')
          expect(page).to have_css('ul.some_base_class__list')
        end
      end
    end

    describe 'concerning title' do
      let(:base_class) { 'some_base_class' }

      context 'when a title is provided' do
        let(:title) { 'some_title' }

        it 'renders the title' do
          expect(page).to have_css('h6.some_base_class__title')
        end
      end

      context 'when there is no title provided' do
        let(:title) { nil }

        it 'does not render the title' do
          expect(page).to have_no_css('h6.some_base_class__title')
        end
      end
    end
  end
end
