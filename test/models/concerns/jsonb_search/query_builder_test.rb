require "test_helper"

class JsonbSearch::QueryBuilderTest < ActiveSupport::TestCase
  test 'query string' do
    query = { name: 'violet' } 
    jsonb_query = JsonbSearch::QueryBuilder.build_jsonb_query(:properties, query)

    assert_equal "lower(properties ->> 'name') = lower('violet')", jsonb_query
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
end