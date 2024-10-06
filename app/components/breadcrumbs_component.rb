# frozen_string_literal: true

class BreadcrumbsComponent < ViewComponent::Base
  SEPARATOR = '&nbsp;&raquo;&nbsp;'.freeze
  BASE_CLASS = 'breadcrumbs'.freeze

  attr_reader :taxon

  def initialize(taxon)
    @taxon = taxon
  end

  def call
    return if current_page?('/') || taxon.nil?

    content_tag(:div, class: BASE_CLASS) do
      content_tag(:nav, class: breadcrumb_class) do
        content_tag(:ol, itemscope: '', itemtype: 'https://schema.org/BreadcrumbList') do
          raw(items.map(&:mb_chars).join)
        end
      end
    end
  end

  private

  def items
    crumbs.map.with_index do |crumb, index|
      content_tag(:li, itemprop: 'itemListElement', itemscope: '', itemtype: 'https://schema.org/ListItem') do
        item_link(crumb, index) + (crumb == crumbs.last ? '' : raw(SEPARATOR))
      end
    end
  end

  def item_link(crumb, index)
    link_to(crumb[:url], itemprop: 'item') do
      content_tag(:span, crumb[:name], itemprop: 'name') +
        tag('meta', { itemprop: 'position', content: (index + 1).to_s }, false, false)
    end
  end

  def crumbs
    return @crumbs if @crumbs

    @crumbs = [
      { name: t('spree.home'), url: helpers.root_path },
      { name: t('spree.products'), url: helpers.products_path }
    ]

    @crumbs += taxon.ancestors.map do |ancestor|
      { name: ancestor.name, url: helpers.nested_taxons_path(ancestor.permalink) }
    end

    @crumbs << { name: taxon.name, url: helpers.nested_taxons_path(taxon.permalink) }

    @crumbs
  end

  def breadcrumb_class
    "#{BASE_CLASS}__content"
  end
end
