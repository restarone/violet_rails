class EMailbox < ApplicationMailbox
  def process
    recipient = mail.to
    subdomain = recipient[0].split('@')[0]
    Apartment::Tenant.switch subdomain do
      if mail.multipart?
        document = Nokogiri::HTML(mail.html_part.body.decoded)
        mail.attachments.map do |attachment|
          blob = ActiveStorage::Blob.create_after_upload!(
            io: StringIO.new(attachment.body.to_s),
            filename: attachment.filename,
            content_type: attachment.content_type,
          )
          if attachment.content_id.present?
            # remove the beginning and end < >
            content_id = document.content_id[1...-1]
            element = body.at_css "img[src='cid#{content_id}'"
            element.replace "<action-text-attachment sgid=\"#{blob.attachable_sgid}\" content-type=\"#{attachment.content_type}\" filename=\"#{attachment.filename}\"></action-text-attachment>"
          end
        end
        
        message = Message.create(
          title: mail.subject,
          content: document.at_css('body').inner_html.encode('utf-8')
        )
      end
    end
  end
end
