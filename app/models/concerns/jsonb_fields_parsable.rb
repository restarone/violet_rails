# Parse jsonb fields before saving to db
module JsonbFieldsParsable
    extend ActiveSupport::Concern

    included do
      before_save :parse_jsonb_fields
    end

    def parse_jsonb_fields
      jsonb_fields = self.class.columns.select{|cl| cl.type === :jsonb}.map(&:name).map(&:to_sym)
      jsonb_fields.each do |field|
        field_value = self[field]
        unless field_value.is_a?(Enumerable) || field_value.blank?
          self[field] = JSON.parse(field_value)
        end
      end
    end
  end