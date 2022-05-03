class ConvertJsonStringPropertiesToJson < ActiveRecord::Migration[6.1]
  def up
    [ApiNamespace, ApiAction, ApiResource, ExternalApiClient, ApiForm].each do |klass|
      klass.all.each do |obj|
        jsonb_fields = klass.columns.select{|cl| cl.type === :jsonb}.map(&:name).map(&:to_sym)
        jsonb_fields.each do |field|
          field_value = obj[field]
          unless field_value.is_a?(Enumerable) || field_value.blank?
            begin
              obj.update(field => JSON.parse(field_value))
            rescue JSON::ParserError => e
              # Manually check and fix invalid JSON string
              error_logger.error("Entity: #{klass.to_s}, Object Id: #{obj.id}, Field: #{field}, Field Value: #{field_value}")
            end
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

  def error_logger
    @@error_logger ||= Logger.new("#{Rails.root}/log/parse_json_string_error.log")
  end
end
