require "test_helper"

class DynamicAttributeTest < ActiveSupport::TestCase
  setup do
    # test concern in isolation
    @dummy_class = Class.new do
      include ActiveModel::Model

      def self.name
        'Test'
      end

      def initialize(test_column: nil)
          @test_column = test_column
      end

      include ActiveModel::Validations
      include DynamicAttribute
      attr_accessor :test_column
      attr_accessor :api_resource

      attr_dynamic :test_column
    end
  end  

  test 'should respond to dynamic methods if dynamic field is safe' do
    safe_instance = @dummy_class.new(test_column: "Test \#{1 + 1}")
    assert safe_instance.valid?
    assert_respond_to safe_instance, :test_column_evaluated
    assert_equal safe_instance.test_column_evaluated, 'Test 2'
  end

  test 'should raise invalid record error dynamic field contains unsafe string' do
    unsafe_instance = @dummy_class.new(test_column: "Test \#{User.destroy_all}")
    refute unsafe_instance.valid?
    assert_no_difference "User.all.size" do
      assert_raises ActiveRecord::RecordInvalid do
        unsafe_instance.test_column_evaluated
      end
    end
  end

  test 'should raise invalid record error if dynamic field contains encoded unsafe string' do
    unsafe_instance = @dummy_class.new(test_column: "&lt;%=%20eval%20%1+2%20%&gt;")
    refute unsafe_instance.valid?
    assert_no_difference "User.all.size" do
      assert_raises ActiveRecord::RecordInvalid do
        unsafe_instance.test_column_evaluated
      end
    end
  end

  test 'should support erb syntax' do
    api_resource_test = api_resources(:user)
    erb_syntax = '<% food = "Ice cream" %>'\
                 '<div>I like <%= food %></div>'\
                 '<% if api_resource.properties["boolean"] %>'\
                  '<div><%= api_resource.properties["first_name"] %></div>'\
                 '<% end %>' 
    
    safe_instance = @dummy_class.new(test_column: erb_syntax)
    safe_instance.api_resource = api_resource_test
    assert safe_instance.valid?
    assert_respond_to safe_instance, :test_column_evaluated
    assert_equal safe_instance.test_column_evaluated, "<div>I like Ice cream</div>"

    api_resource_test.update(properties: api_resource_test.properties.merge({"boolean": true}))
    assert_equal safe_instance.test_column_evaluated, "<div>I like Ice cream</div><div>#{api_resource_test.properties['first_name']}</div>"
  end

  test 'should raise invalid record error if erb contains unsafe string' do
    unsafe_instance = @dummy_class.new(test_column: "Test <% User.destroy_all %>")
    refute unsafe_instance.valid?
    assert_no_difference "User.all.size" do
      assert_raises ActiveRecord::RecordInvalid do
        unsafe_instance.test_column_evaluated
      end
    end
  end

  test 'should be able to access current_user and current_visit' do
    erb_syntax = "<%= current_user.id %> and <%= current_visit.id %>"

    Current.user = users(:one)
    Current.visit = ahoy_visits(:public)

    safe_instance = @dummy_class.new(test_column: erb_syntax)
    assert_equal safe_instance.test_column_evaluated, "#{Current.user.id} and #{Current.visit.id}"
  end

  test 'should raise no method error if undefined methods are referenced' do
    safe_instance = @dummy_class.new(test_column: "<%= undefined_method() %>")
    assert_raises NoMethodError do
      safe_instance.test_column_evaluated
    end
  end

  test 'should raise syntax error if erb syntax is wrong' do
    # notice the missing closing end for if
    erb_syntax = '<% if true %>'\
                    '<div>Violet Rails</div>'

    safe_instance = @dummy_class.new(test_column: erb_syntax)
    assert_raises SyntaxError do
      safe_instance.test_column_evaluated
    end
  end

  test 'should support both string interpolation and erb syntax on same attribute' do
    safe_instance = @dummy_class.new(test_column: "<%= 1 + 1 %> and \#{2 + 2}")
    assert_equal safe_instance.test_column_evaluated, "2 and 4"
  end

  test 'should support both string interpolation and erb syntax on json attribute' do
    safe_instance = @dummy_class.new(test_column: { test_key: "<%= 1 + 1 %> and \#{2 + 2}" })
    assert_equal safe_instance.test_column_evaluated, { test_key: "2 and 4" }.to_json
  end

  test 'should unescape html and decode uri-encoded characters' do
    safe_instance = @dummy_class.new(test_column: ActionText::RichText.new(body: '<a href="<%= 2 and 4 %>">'))
    # action text encoded and escaped special characters
    assert_equal "<div class=\"trix-content\">\n  <a href=\"&lt;%=%202%20and%204%20%&gt;\"></a>\n</div>\n", safe_instance.test_column.to_s
    assert_equal "<div class=\"trix-content\">\n  <a href=\"4\"></a>\n</div>\n", safe_instance.test_column_evaluated
  end
end