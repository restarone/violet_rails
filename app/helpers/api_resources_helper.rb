module ApiResourcesHelper
  def show_file(file)
    return unless file.attached?

    if file.content_type.include?('image')
      image_tag rails_blob_url(file, subdomain: Apartment::Tenant.current), height: 200, width: 200
    else
      link_to file.filename.to_s,  rails_blob_url(file, subdomain: Apartment::Tenant.current), target: '_blank'
    end
  end

  def object_fields(properties) 
      keys = []
      properties.each do |key, value|
        keys << key if value.is_a?(Hash)
      end
      keys
  end

  def map_color(stage)
    case stage
    when 'initialize'
      'blue'
    when 'executing'
      'orange'
    when 'complete'
      'green'
    when 'failed'
      'red'
    end
  end
end
