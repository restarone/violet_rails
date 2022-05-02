class ConvertJsonStringPropertiesToJson < ActiveRecord::Migration[6.1]
  def up
    [ApiNamespace, ApiAction, ApiResource, ExternalApiClient, ApiForm].each do |klass|
      klass.all.each do |obj|
        jsonb_fields = klass.columns.select{|cl| cl.type === :jsonb}.map(&:name).map(&:to_sym)
        jsonb_fields.each do |field|
          field_value = obj[field]
          unless field_value.is_a?(Enumerable) || field_value.blank?
            obj.update(field => JSON.parse(field_value))
          end
        end
      end
    end
  end
  
  def down
    [ApiNamespace, ApiAction, ApiResource, ExternalApiClient, ApiForm].each do |klass|
      klass.all.each do |obj|
        jsonb_fields = klass.columns.select{|cl| cl.type === :jsonb}.map(&:name).map(&:to_sym)
        jsonb_fields.each do |field|
          field_value = obj[field]
          if field_value.is_a?(Enumerable)
            obj.update(field => field_value.to_json)
          end
        end
      end
    end
  end
end
