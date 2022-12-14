class EMailbox < ApplicationMailbox

  def process
    subject = mail.subject
    recipients = mail.to.map{|email| Mail::Address.new(email)}
    # recipients =[mail.to]
    recipients.each do |address|
      # domain = address.split('@').first
      # schema_domain = domain == Subdomain::ROOT_DOMAIN_EMAIL_NAME ? 'public' : domain
      schema_domain = address.local == Subdomain::ROOT_DOMAIN_EMAIL_NAME ? 'public' : address.local
      subdomain_name = schema_domain == 'public' ? Subdomain::ROOT_DOMAIN_NAME : schema_domain
      next if !Subdomain.find_by(name: subdomain_name)
      Apartment::Tenant.switch schema_domain do
        mailbox = Mailbox.first_or_create
        # if mailbox
        #   message_thread = MessageThread.find_or_create_by(
        #     current_email_message_id: mail.in_reply_to
        #   )
        #   message_thread.update(recipients: mail.from, subject: subject)
        #   message = Message.create!(
        #     email_message_id: mail.message_id,
        #     message_thread: message_thread,
        #     content: body,
        #     from: mail.from.join(', '),
        #     attachments: (attachments + multipart_attached).map{ |a| a[:blob] }
        #   )
        #   ApiNamespace::Plugin::V1::SubdomainEventsService.new(message).track_event
        # end

        if mailbox
          if mail.in_reply_to && in_reply_to_message = Message.find_by(email_message_id: mail.in_reply_to)
            message_thread = in_reply_to_message.message_thread
          else
            message_thread = MessageThread.create!(
              recipients: mail.from,
              subject: subject
            )
          end

          message = Message.create!(
            email_message_id: mail.message_id,
            message_thread: message_thread,
            content: body,
            from: mail.from.join(', '),
            attachments: (attachments + multipart_attached).map{ |a| a[:blob] }
          )
          ApiNamespace::Plugin::V1::SubdomainEventsService.new(message).track_event
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
