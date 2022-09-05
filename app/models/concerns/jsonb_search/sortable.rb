# Search Jsonb fields
# Simple query format => { name: 'violet' }
# Extended format => { name: { value: 'violet', option: 'PARTIAL' } }, option is optional, default is EXACT

module JsonbSearch
  module Sortable
    extend ActiveSupport::Concern
  
    included do 
      scope :jsonb_order, -> (column_name, query) { order(build_sort_query(query)) }

      def self.build_sort_query(query)
        q_string = query.map do |key, value|
          unless value.is_a? Hash
            "#{key} #{value}"
          else 
            generate_nested_sort_query(value, key)
          end
        end.join(', ')

        Arel.sql(q_string)
      end

      def self.generate_nested_sort_query(query, query_string)
        nested_key = query.keys.join
        nested_value = query[nested_key]

        if nested_value.is_a? String
          "#{query_string} ->> '#{nested_key}' #{nested_value}"
        else 
          generate_nested_sort_query(nested_value, "#{query_string} -> '#{nested_key}'")
        end
      end
    end
  end
end