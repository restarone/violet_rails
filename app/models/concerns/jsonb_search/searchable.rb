# Search Jsonb fields
# Simple query format => { name: 'violet' }
# Extended format => { name: { value: 'violet', option: 'PARTIAL' } }, option is optional, default is EXACT

module JsonbSearch
  module Searchable
    extend ActiveSupport::Concern
    include JsonbSearch::QueryBuilder

    included do 
      scope :jsonb_search, ->(column_name, query) { where(JsonbSearch::QueryBuilder.build_jsonb_query(column_name, query)) }
    end
  end
end