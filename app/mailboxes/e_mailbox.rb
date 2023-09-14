class EMailbox < ApplicationMailbox

  def process
    subject = sanitize_email_subject_prefixes(mail.subject)
    recipients = mail.to.map{|email| Mail::Address.new(email)}
    recipients.each do |address|
      schema_domain = address.local == Subdomain::ROOT_DOMAIN_EMAIL_NAME ? 'public' : address.local
      next if !Subdomain.find_by(name: schema_domain)
      Apartment::Tenant.switch schema_domain do
        mailbox = Mailbox.first_or_create
        if mailbox
          if mail.in_reply_to && in_reply_to_message = Message.find_by(email_message_id: mail.in_reply_to)
            message_thread = in_reply_to_message.message_thread
          else
            message_thread = MessageThread.find_or_create_by(
              recipients: mail.from,
              subject: subject
            )
          end
          uploaded_attachments = attachments
          multipart_attachments = multipart_attached
          message = Message.create!(
            email_message_id: mail.message_id,
            message_thread: message_thread,
            content: body(uploaded_attachments),
            from: mail.from.join(', '),
            attachments: (uploaded_attachments + multipart_attachments).map{ |a| a[:blob] }
          )
          message_thread.update(unread: true)
          process_attachments(uploaded_attachments) if uploaded_attachments.size > 0
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

  def body(uploaded_blobs)
    if mail.multipart? && mail.html_part
      document = Nokogiri::HTML(mail.html_part.body.decoded)
      uploaded_blobs.map do |attachment_hash|
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

  private
  def sanitize_email_subject_prefixes(subject)
    return subject if subject.blank?

    # There are some standard email subject prefixes which gets prepended in the email's subject.
    # examples: 'Re: ', 're: ', 'FWD: ', 'Fwd: ', 'Fw: '
    subject.gsub(/^((re|fw(d)?): )/i, '')
  end

  def process_attachments(blobs)
    # process .ics files
    ics_files = blobs.select {|attachment| attachment[:original].content_type.include?('.ics') }
    ics_files.each do |ics_file|
      ics_string = ics_file[:blob].download
      calendars = Icalendar::Calendar.parse(ics_string)
      calendars.each do |calendar|
        calendar.events.each do |event|
          existing_meeting = Meeting.find_by(external_meeting_id: event.uid.to_s)
          if existing_meeting
            # handle replies to meeting invites
            existing_meeting.update(updated_at: Time.now)
          else
            meeting = Meeting.create!(
              name: event.summary,
              external_meeting_id: event.uid,
              start_time: event.dtstart,
              end_time: event.dtend,
              timezone: Array.wrap(event.dtstart.ical_params['tzid']).join('-'),
              description: event.description,
              participant_emails: event.attendee.map{|uri| uri.to },
              location: event.location,
              status: 'TENTATIVE',
              custom_properties: event.custom_properties,
            )
          end
        end
      end
    end
  end
end
