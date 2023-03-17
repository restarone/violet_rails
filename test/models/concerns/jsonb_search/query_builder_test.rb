require "test_helper"

class JsonbSearch::QueryBuilderTest < ActiveSupport::TestCase
  test 'query string' do
    query = { name: 'violet' } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal "lower(properties ->> 'name') = lower('violet')", jsonb_query
  end

  test 'query string containing single quote \'' do
    query = { name: "violet's rails" } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal "lower(properties ->> 'name') = lower('violet''s rails')", jsonb_query
  end

  test 'query string containing double quote "' do
    query = { name: '"violet rails"' } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal "lower(properties ->> 'name') = lower('\"violet rails\"')", jsonb_query
  end

  test 'query string - extended format' do
    query = { name: { value: 'violet', option: 'EXACT' } } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal "lower(properties ->> 'name') = lower('violet')", jsonb_query
  end

  test 'query string - partial' do
    query = { name: { value: 'violet', option: 'PARTIAL' } } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal "lower(properties ->> 'name') LIKE lower('%violet%')", jsonb_query
  end

  test 'query string - multiple properties' do
    query = { name: { value: 'violet' }, age: 20 } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal "lower(properties ->> 'name') = lower('violet') AND lower(properties ->> 'age') = lower('20')", jsonb_query
  end

  test 'query string - KEYWORDS: splits the provided value into words' do
    query = { name: { value: 'violet rails development', option: 'KEYWORDS' } } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    expected_query = "lower(properties ->> 'name') LIKE lower('%violet%') OR lower(properties ->> 'name') LIKE lower('%rails%') OR lower(properties ->> 'name') LIKE lower('%development%') OR lower(properties ->> 'name') LIKE lower('%violet rails development%')"

    assert_equal expected_query, jsonb_query
  end

  test 'query string - KEYWORDS: splits the provided value into words by skipping the individual query for stopwords' do
    query = { name: { value: 'a hope for future', option: 'KEYWORDS' } } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    expected_query = "lower(properties ->> 'name') LIKE lower('%hope%') OR lower(properties ->> 'name') LIKE lower('%future%') OR lower(properties ->> 'name') LIKE lower('%a hope for future%')"

    assert_equal expected_query, jsonb_query
  end

  test 'query string - nested' do
    query = { foo: { bar: 'baz' }  } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal "lower(properties -> 'foo' ->> 'bar') = lower('baz')", jsonb_query
  end

  test 'query json - exact' do
    query = { object: { value: { foo: 'bar' }, option: 'EXACT'} } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal "properties -> 'object' = '#{query[:object][:value].to_json}'", jsonb_query
  end

  test 'query json - partial' do
    query = { object: { value: { foo: 'bar' }, option: 'PARTIAL'} } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal "properties -> 'object' @> '#{query[:object][:value].to_json}'", jsonb_query
  end

  test 'query array - exact' do
    query = { array: ['foo', 'bar'] } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal "properties -> 'array' @> '#{query[:array].to_json}' AND properties -> 'array' <@ '#{query[:array].to_json}'", jsonb_query
  end

  test 'query array - partial - no match option' do
    query = { array: { value: ['foo', 'bar'], option: 'PARTIAL' } } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal "properties -> 'array' @> '#{query[:array][:value].to_json}'", jsonb_query
  end

  test 'query array - partial match all' do
    query = { array: { value: ['foo', 'bar'], option: 'PARTIAL', match: 'ALL' } } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal "properties -> 'array' @> '#{query[:array][:value].to_json}'", jsonb_query
  end

  test 'query array - partial match any' do
    query = { array: { value: ['foo', 'bar'], option: 'PARTIAL', match: 'ANY' } } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal "properties -> 'array' ? '#{query[:array][:value][0]}' OR properties -> 'array' ? '#{query[:array][:value][1]}'", jsonb_query
  end

  test 'query array - KEYWORDS match ALL' do
    query = { array: { value: ['hello world', 'bar'], option: 'KEYWORDS', match: 'ALL' } } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal "lower(properties ->> 'array'::text) LIKE lower('%hello%') AND lower(properties ->> 'array'::text) LIKE lower('%world%') AND lower(properties ->> 'array'::text) LIKE lower('%bar%')", jsonb_query
  end

  test 'query array - KEYWORDS match ANY' do
    query = { array: { value: ['hello world', 'bar'], option: 'KEYWORDS', match: 'ANY' } } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal "lower(properties ->> 'array'::text) LIKE lower('%hello%') OR lower(properties ->> 'array'::text) LIKE lower('%world%') OR lower(properties ->> 'array'::text) LIKE lower('%bar%')", jsonb_query
  end

  test 'query array - nested' do
    query = { foo: { array: ['foo', 'bar'] } } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal "properties -> 'foo' -> 'array' @> '#{query[:foo][:array].to_json}' AND properties -> 'foo' -> 'array' <@ '#{query[:foo][:array].to_json}'", jsonb_query 

    # extended query 
    query = { foo: { array: { value: ['foo', 'bar'], option: 'PARTIAL' } } } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal jsonb_query, "properties -> 'foo' -> 'array' @> '#{query[:foo][:array][:value].to_json}'"

    # extended query - match all
    query = { foo: { array: { value: ['foo', 'bar'], option: 'PARTIAL', match: 'ALL' } } } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal "properties -> 'foo' -> 'array' @> '#{query[:foo][:array][:value].to_json}'", jsonb_query

    # extended query - match any
    query = { foo: { array: { value: ['foo', 'bar'], option: 'PARTIAL', match: 'ANY' } } } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal "properties -> 'foo' -> 'array' ? '#{query[:foo][:array][:value][0]}' OR properties -> 'foo' -> 'array' ? '#{query[:foo][:array][:value][1]}'", jsonb_query
  end

  test 'query string - multiple properties - match any condition' do
    query = { name: 'violet', age: 20 }
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query, JsonbSearch::QueryBuilder::MATCH_OPTION[:ANY])

    assert_equal "lower(properties ->> 'name') = lower('violet') OR lower(properties ->> 'age') = lower('20')", jsonb_query
  end

  test 'query string - extended format - multiple properties - match any condition' do
    query = { name: { value: 'violet', option: 'PARTIAL' }, age: { value: 20, option: 'EXACT' } }
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query, JsonbSearch::QueryBuilder::MATCH_OPTION[:ANY])

    assert_equal "lower(properties ->> 'name') LIKE lower('%violet%') OR lower(properties ->> 'age') = lower('20')", jsonb_query
  end
end