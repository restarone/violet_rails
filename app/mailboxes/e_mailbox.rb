class EMailbox < ApplicationMailbox

  def process
    recipient = mail.to
    subdomain = recipient[0].split('@')[0]
    subject = mail.subject
    recipients = recipient.map{|email| Mail::Address.new(email)}
    recipients.each do |address|
      schema_domain = address.domain.split('.')[0]
      local_user = address.local
      Apartment::Tenant.switch schema_domain do
        email_alias = EmailAlias.find_by(name: local_user)
        user = email_alias.user
        mailbox = user.mailbox
        if email_alias && user && mailbox
          message_thread = MessageThread.first_or_create(
            subject: subject,
            mailbox: mailbox,
          )
          message_thread.update(recipients: mail.from)
          message = Message.create!(
            message_thread: message_thread,
            content: body,
            from: mail.from[0],
            attachments: (attachments + multipart_attached).map{ |a| a[:blob] }
          )
        else
          # this is a bounce (came up to the correct subdomain, but nonexistant local name)
        end
      end
    end
  end

  def attachments
    return mail.attachments.map do |attachment|
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(attachment.body.to_s),
        filename: attachment.filename,
        content_type: attachment.content_type,
      )
      { original: attachment, blob: blob }
    end
  end

  def multipart_attached
    blobs = Array.new
    if mail.multipart?
      mail.parts.each do |part|
        if !part.text? && part.has_content_id?
          blob = ActiveStorage::Blob.create_and_upload!(
            io: StringIO.new(part.decoded),
            filename: part.filename,
            content_type: part.content_type,
          )
          blobs  << { original: part, blob: blob }
        end
      end
    end
    return blobs
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
          if element
            element.replace "<action-text-attachment sgid=\"#{blob.attachable_sgid}\" content-type=\"#{attachment.content_type}\" filename=\"#{attachment.filename}\"></action-text-attachment>"
          end
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
