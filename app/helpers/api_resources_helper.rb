module ApiResourcesHelper
  def show_file(file)
    return unless file.attached?

    if file.content_type.include?('image')
      image_tag file, height: 200, width: 200
    else
      link_to file.filename.to_s, file, target: '_blank'
    end
  end
end
