# Ensure jsonb fields always store hash 
# Parse JSON string to hash before saving to db if provided value is string
# Raise validation error if JSON string is not parsable

module JsonbFieldsParsable
    extend ActiveSupport::Concern

    included do
      validate :ensure_enumerable_in_jsonb_fields
    end

    def ensure_enumerable_in_jsonb_fields
      jsonb_fields = self.class.columns.select{|cl| (cl.type == :jsonb || cl.type == :json)}.map(&:name).map(&:to_sym)
      jsonb_fields.each do |field|
        field_value = self[field]
        unless field_value.is_a?(Enumerable) || field_value.blank?
          begin 
            self[field] = JSON.parse(field_value)
          rescue JSON::ParserError => e
            errors.add(field, 'Invalid Json Format')
          end
        end
        # check if order has been changed
        self.send("#{field}_will_change!".to_sym) unless self.send("#{field}_was".to_sym).to_json == self[field].to_json
      end
    end
  end