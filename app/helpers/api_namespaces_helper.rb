module ApiNamespacesHelper
  def api_base_url(subdomain, namespace)
    "#{subdomain.hostname}/api/#{namespace.version}/#{namespace.slug}"
  end

  def graphql_base_url(subdomain, namespace)
    "#{subdomain.hostname}/graphql"
  end

  def system_paths
    Comfy::Cms::Page.all.pluck(:full_path)
  end

  def api_html_renderer_dynamic_properties(namespace, search_option = nil)
    custom_properties = {}
    fields_in_properties = namespace.properties.keys

    namespace.properties.values.each_with_index do |obj,index|
      if obj.present? && obj != "nil" && obj != "\"\""
        if search_option.present?
          next if !obj.is_a?(Array) && !obj.is_a?(String)

          custom_properties[fields_in_properties[index]] = {
            value: obj.is_a?(Array) ? obj.first(1) : obj.split.first,
            option: search_option
          }
        else
          custom_properties[fields_in_properties[index]] = obj;
        end
      end
    end

    # sanitize the text to properly display
    JSON.parse(custom_properties.to_json, object_class: OpenStruct).to_s.gsub(/=/,': ').gsub(/#<OpenStruct/,'{').gsub(/>/,'}').gsub("\\", "'").gsub(/"'"/,'"').gsub(/'""/,'"')
  end
end
