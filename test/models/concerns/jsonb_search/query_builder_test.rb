require "test_helper"

class JsonbSearch::QueryBuilderTest < ActiveSupport::TestCase
  test 'query string' do
    query = { name: 'violet' } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal jsonb_query, "lower(properties ->> 'name') = lower('violet')"
  end

  test 'query string - extended format' do
    query = { name: { value: 'violet', option: 'EXACT' } } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal jsonb_query, "lower(properties ->> 'name') = lower('violet')"
  end

  test 'query string - partial' do
    query = { name: { value: 'violet', option: 'PARTIAL' } } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal jsonb_query, "lower(properties ->> 'name') LIKE lower('%violet%')"
  end

  test 'query string - multiple properties' do
    query = { name: { value: 'violet' }, age: 20 } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal jsonb_query, "lower(properties ->> 'name') = lower('violet') AND lower(properties ->> 'age') = lower('20')"
  end

  test 'query string - nested' do
    query = { foo: { bar: 'baz' }  } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal jsonb_query, "lower(properties -> 'foo' ->> 'bar') = lower('baz')"
  end

  test 'query json - exact' do
    query = { object: { value: { foo: 'bar' }, option: 'EXACT'} } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal jsonb_query, "properties -> 'object' = '#{query[:object][:value].to_json}'"
  end

  test 'query json - partial' do
    query = { object: { value: { foo: 'bar' }, option: 'PARTIAL'} } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal jsonb_query, "properties -> 'object' @> '#{query[:object][:value].to_json}'"
  end

  test 'query array - exact' do
    query = { array: ['foo', 'bar'] } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal jsonb_query, "properties -> 'array' @> '#{query[:array].to_json}' AND properties -> 'array' <@ '#{query[:array].to_json}'"
  end

  test 'query array - partial' do
    query = { array: { value: ['foo', 'bar'], option: 'PARTIAL' } } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal jsonb_query, "properties -> 'array' @> '#{query[:array][:value].to_json}'"
  end

  test 'query array - nested' do

    query = { foo: { array: ['foo', 'bar'] } } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal jsonb_query, "properties -> 'foo' -> 'array' @> '#{query[:foo][:array].to_json}' AND properties -> 'foo' -> 'array' <@ '#{query[:foo][:array].to_json}'"

    # extended query 
    query = { foo: { array: { value: ['foo', 'bar'], option: 'PARTIAL' } } } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal jsonb_query, "properties -> 'foo' -> 'array' @> '#{query[:foo][:array][:value].to_json}'"
  end
end