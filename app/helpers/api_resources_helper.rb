module ApiResourcesHelper
  def show_file(file, label)
    return unless file.attached?

    file_url = rails_blob_url(file, subdomain: Apartment::Tenant.current)
    output = ''
    output << <<-HTML
    #{image_tag (file.content_type.include?('image') ? file_url : ''), height: 200, width: 200, id: "#{label.parameterize.underscore}_preview_img", style: "display: #{file.content_type.include?('image') ? 'block' : 'none'};"}
    #{video_tag (file.content_type.include?('video') ? file_url : ''), height: 200, controls: true, id: "#{label.parameterize.underscore}_preview_video", style: "display: #{file.content_type.include?('video') ? 'block' : 'none'};"}
    #{link_to file.filename.to_s, file_url, target: '_blank', id: "#{label.parameterize.underscore}_preview_download_link", style: "display: #{file.content_type.match?(/video|image/) ? 'none' : 'block'};"}
    HTML

    output.html_safe
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
