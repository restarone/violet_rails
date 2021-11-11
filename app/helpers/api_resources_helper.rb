module ApiResourcesHelper
  def show_file(file)
    return unless file.attached?

    if file.content_type.include?('image')
      image_tag file, height: 200, width: 200
    else
      link_to file.filename.to_s, file, target: '_blank'
    end
  end

  def object_fields(properties) 
      keys = []
      JSON.parse(properties).each do |key, value|
        keys << key if value.class.to_s == 'Hash'
      end
      keys
  end
end
