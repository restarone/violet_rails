module JsonbSearch
  module QueryBuilder
    QUERY_OPTION = {
      EXACT: 'EXACT',
      PARTIAL: 'PARTIAL'
    }.freeze

    class << self
      def build_jsonb_query(column_name, query_params)
        parsed_params = parse_params(query_params.deep_symbolize_keys)
        build(parsed_params, column_name)
      end

      private

      def parse_params(query_params)
        queries = []

        query_params.each do |key, value|
          if value.is_a?(Hash) && value.key?(:value)
            # { name: { value: 'violet', query }} || { name: { value: 'violet', option: 'EXACT' }}
            queries << { option: value[:option] || QUERY_OPTION[:EXACT], key: key, value: value[:value] }
          elsif value.is_a?(Hash)
            # { foo: { bar: 'baz', wat: 'up' }}
            value.each do |k, v|
              if v.is_a?(Hash) && value.key?(:value)
                queries <<  { key: key, value: [{ option: v[:option] || QUERY_OPTION[:EXACT], key: k, value: v[:value] }] }
              else
                queries << { key: key, value: [{ option: QUERY_OPTION[:EXACT], key: k, value: v }]}
              end
            end
          else
            # { name: 'violet' } || { tags: ['violet', 'rails'] }
            queries << { option: QUERY_OPTION[:EXACT], key: key, value: value }
          end
        end

        queries
      end

      def build(queries, column_name)
        queries_array = queries.map do |object|
          generate_query(object, column_name)
        end
        queries_array.join(' AND ')
      end

      def generate_query(param, query_string)
        key = param[:key]
        term = param[:value]
        option = param[:option]
        case term.class.to_s

        when 'Hash'
          return hash_query(key, term, option, query_string)
        when 'Array'
          if option
            return array_query(key, term, option, query_string)
          else
            term.each do |obj|
              # "column -> 'property' ->> 'nested property' = 'term'" 
              query_string = generate_query(obj, "#{query_string} -> '#{key}'")
            end

            return query_string
          end
        else
          return string_query(key, term, option, query_string)
        end
      end

      # "column ->> 'property' = 'term'" 
      def string_query(key, term, option, query)
        if option == QUERY_OPTION[:PARTIAL]
          term = "%#{term}%"
          operator = 'LIKE'
        end

        "lower(#{query} ->> '#{key}') #{operator || '='} lower('#{term}')"
      end

      # "column -> 'property' @> '{/"search/": /"term/"}'" 
      def hash_query(key, term, option, query)
        operator = option == QUERY_OPTION[:PARTIAL] ? '@>' : '='
        "#{query} -> '#{key}' #{operator} '#{term.to_json}'"
      end

      # "column -> 'property' ? '['term']'" 
      def array_query(key, term, option, query)
        if option == QUERY_OPTION[:PARTIAL]
          "#{query} -> '#{key}' @> '#{term.to_json}'"
        else
          "#{query} -> '#{key}' @> '#{term.to_json}' AND  #{query} -> '#{key}' <@ '#{term.to_json}'"
        end
      end
    end
  end
end