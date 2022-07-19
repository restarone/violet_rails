# evaluate dynamic columns
# adding attribute defined by attr_dynamic parameters
# method attributed will be created as <coulmn_name>_evaluated
# example attr_dynamic :custom_message will add a method custom_message_evaluated
# column content example: Hi my name is #{api_resource.properties["first_name"]}

module DynamicAttribute
    extend ActiveSupport::Concern
    include Rails.application.routes.url_helpers

    included do
      def parse_dynamic_attribute(value)
        return unless value.present?

        raise ActiveRecord::RecordInvalid.new(self) unless self.valid?

        parsed_text = value
        # couldn't gsub directly because of escape characters added by ruby
        # eval failed on "\#{api_resource.properties[\"String\"]}"
        value.scan(/\#\{(.*?)\}/).each do |code|
          parsed_text = parsed_text.sub!("\#{#{code[0]}}", eval(code[0]).to_s)
        end

        # parse erb
        parser = ERB.new(CGI.unescapeHTML(parsed_text))
        result = parser.result(binding)
        result.html_safe
      end

      def attribute_value_string(attribute)
        value = public_send(attribute.to_sym)
        # Deep copy of non-enumerable column like string-type would get passed and the evaluated value would get reflected as change.
        value.is_a?(Enumerable) ? value.to_json : value.to_s.dup
      end

      # Fetching session specific data should be defined here.
      def current_user
        Current.user
      end

      def current_visit
        Current.visit
      end
    end
  
    class_methods do
      def attr_dynamic(*attributes) # rubocop:disable Metrics/AbcSize
        attributes.each do |attribute|
          # all dynamic attributes should be safe
          validates attribute.to_sym, safe_executable: true

          define_method("#{attribute}_evaluated") do
            parse_dynamic_attribute(attribute_value_string(attribute))
          end
        end
      end
    end
  end