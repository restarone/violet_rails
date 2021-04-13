class EMailbox < ApplicationMailbox
  def process
    recipient = mail.to
    subdomain = recipient[0].split('@')[0]
    Apartment::Tenant.switch subdomain do
      message = Message.create(
        title: mail.subject,
        content: body,
        from: mail.from[0],
        attachments: attachments.map{ |a| a[:blob] }
      )
    end
  end

  def attachments
    @_attachments = mail.attachments.map do |attachment|
      blob = ActiveStorage::Blob.create_after_upload!(
        io: StringIO.new(attachment.body.to_s),
        filename: attachment.filename,
        content_type: attachment.content_type,
      )
      { original: attachment, blob: blob }
    end
  end


  def body
    if mail.multipart? && mail.html_part
      document = Nokogiri::HTML(mail.html_part.body.decoded)
      attachments.map do |attachment_hash|
        attachment = attachment_hash[:original]
        blob = attachment_hash[:blob]
        if attachment.content_id.present?
          # Remove the beginning and end < >
          content_id = attachment.content_id[1...-1]
          element = document.at_css "img[src='cid:#{content_id}']"

          element.replace "<action-text-attachment sgid=\"#{blob.attachable_sgid}\" content-type=\"#{attachment.content_type}\" filename=\"#{attachment.filename}\"></action-text-attachment>"
        end
      end
      document.at_css("body").inner_html.encode('utf-8')
    elsif mail.multipart? && mail.text_part
      mail.text_part.body.decoded
    else
      mail.decoded
    end
  end
end
