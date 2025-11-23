class EmailTemplate < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged
  validates :name, presence: true

  SYMBOL_CAPTURE_PATTERN = /(?<=\{\{)[a-z]+(?:\.[a-z]+)*(?=\}\})/

  def dynamic_segments
    html_doc = Base64.decode64(self.html)
    html_doc.scan(SYMBOL_CAPTURE_PATTERN)
  end

  def inject_dynamic_segments(properties_obj = {})
  # pass a hash of properties or a API Resource instance and get dynamic HTML
  # usage option 1: EmailTemplate.last.inject_dynamic_segments({name: 'hideo kojima', link: "https://mgs.snake"})
  # usage option 2: EmailTemplate.last.inject_dynamic_segments(ApiResource.last)
  # works by extracting any variable defined between: {{}} 
  # example of including a variable called 'name': {{name}}
    
    html_doc = Base64.decode64(self.html)
    symbols = self.dynamic_segments
    symbol_mapping = ActiveSupport::HashWithIndifferentAccess.new
    output = html_doc

    if properties_obj.class == ApiResource
      api_resource = properties_obj
      symbols.each do |symbol|
        symbol_mapping[symbol] = api_resource.properties[symbol]
      end
    elsif properties_obj.class == Hash || properties_obj.class == ActiveSupport::HashWithIndifferentAccess
      symbols.each do |symbol|
        symbol_mapping[symbol] = properties_obj.with_indifferent_access[symbol]
      end
    else
      raise "dynamic segment mapping for Email Template is unrecognized. Please pass a hash of properties or API Resource instance"
    end
    
    symbols.each do |symbol|
      mapped_value = symbol_mapping[symbol]
      raise "dynamic segment token has no value, please ensure a value is provided" if mapped_value.nil? || mapped_value.empty?
      output = output.gsub("{{#{symbol}}}", mapped_value)
    end
    return output
  end
end
