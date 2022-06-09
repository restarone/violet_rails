# adding attribute defined by attr_dynamic parameters
# method attributed will be created as decrypted from column "encrypted_" attribute name
# example attr_dynamic :password will save encrypted password on column encrypted_password
# also create salt if not exist
module DynamicAttribute
    extend ActiveSupport::Concern

    included do
      # custom_message format: api_resource.properties["first_name"]
      def parse_dynamic_attribute(value)
        return unless value.present?

        parsed_text = value
        # couldn't gsub directly because of escape characters added by ruby
        # eval failed on "\#{api_resource.properties[\"String\"]}"
        value.scan(/\#\{(.*?)\}/).each do |code|
          # TODO: sanitize code before eval  
          parsed_text = parsed_text.sub!("\#{#{code[0]}}", eval(code[0]).to_s)
        end
        parsed_text.html_safe
      end

      def attribute_value_string(attribute)
        value = public_send(attribute.to_sym)
        value.is_a?(Enumerable) ? value.to_json : value.to_s
      end
    end
  
    class_methods do
      def attr_dynamic(*attributes) # rubocop:disable Metrics/AbcSize
        attributes.each do |attribute|
          define_method("#{attribute}_evaluated") do
            parse_dynamic_attribute(attribute_value_string(attribute))
          end
        end
      end
    end
  end