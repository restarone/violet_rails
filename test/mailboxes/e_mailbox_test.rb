require "test_helper"

class EMailboxTest < ActionMailbox::TestCase

  setup do
    @restarone_subdomain = Subdomain.find_by(name: 'restarone').name
    Apartment::Tenant.switch @restarone_subdomain do
      mailbox = Subdomain.find_by(name: @restarone_subdomain).initialize_mailbox
      @user = User.first
      @user.update(can_manage_email: true)
    end
    Sidekiq::Testing.fake!
  end

  test "inbound mail routes to correct schema" do
    Apartment::Tenant.switch @restarone_subdomain do 
      assert_difference "MessageThread.all.reload.size" , +1 do 
        assert_difference "Message.all.reload.size", +1 do
          receive_inbound_email_from_mail \
            to: '"Don Restarone" <restarone@restarone.solutions>',
            from: '"else" <else@example.com>',
            subject: "Hello world!",
            body: "Hello?"
        end
      end
    end
  end

  test "inbound mail is tracked if plugin: subdomain/subdomain_events is enabled" do
    subdomains(:public).update(api_plugin_events_enabled: true)
    assert_difference "ApiResource.count", +1 do      
      receive_inbound_email_from_mail \
        to: '"Don Restarone" <www@restarone.solutions>',
        from: '"else" <else@example.com>',
        subject: "Hello world!",
        body: "Hello?"
        Sidekiq::Worker.drain_all
    end
  end

  test "inbound mail routes to correct schema (www/domain apex)" do
    MessageThread.destroy_all
    Apartment::Tenant.switch 'public' do 
      assert_difference "MessageThread.all.reload.size" , +1 do 
        assert_difference "Message.all.reload.size", +1 do
          receive_inbound_email_from_mail \
            to: '"Don Restarone" <www@restarone.solutions>',
            from: '"else" <else@example.com>',
            subject: "Hello world!",
            body: "Hello?"
        end
      end
    end
  end

  test 'direct attachment' do
    Apartment::Tenant.switch @restarone_subdomain do      
      assert_difference "MessageThread.all.reload.size" , +1 do
        assert_difference "Message.all.reload.size", +1 do
          mail = Mail.new(
            from: 'else@example.com',
            to: 'restarone@restarone.solutions',
            subject: 'Logo',
            body: 'Hi, See the logo attached.',
          )
          mail.add_file filename: 'template.eml', content: StringIO.new('Sample Logo')
          create_inbound_email_from_source(mail.to_s).tap(&:route)
        end
      end
    end
  end

  test "inbound multipart mail routes to correct schema" do
    Apartment::Tenant.switch @restarone_subdomain do      
      create_inbound_email_from_mail do      
        from '"else" <else@example.com>'
        to '"Don Restarone" <restarone@restarone.solutions>'
        subject "Hello world!"
        text_part do
          body "hello this is the body"
        end
        html_part do
          body "<h1>Please join us for a party at Bag End</h1>"
        end
      end 
    end
  end

  test "from multipart file" do
    Apartment::Tenant.switch @restarone_subdomain do      
      assert_changes "ActiveStorage::Blob.all.reload.size" do
        email = create_inbound_email_from_fixture('multipart-with-files.eml')
        email.tap(&:route)
        assert Message.last.content
      end
    end
  end

  test "from video attachment" do
    Apartment::Tenant.switch @restarone_subdomain do      
      assert_changes "ActiveStorage::Blob.all.reload.size" do
        email = create_inbound_email_from_fixture('with-video-attachment.eml')
        email.tap(&:route)
        assert Message.last.content
      end
    end
  end

  test "from multipart file (thread)" do
    Apartment::Tenant.switch @restarone_subdomain do      
      assert_changes "ActiveStorage::Blob.all.reload.size" do
        email = create_inbound_email_from_fixture('thread.eml')
        email.tap(&:route)
        assert Message.last.content
      end
    end
  end

  test "when sent to multiple recipients" do
    Apartment::Tenant.switch @restarone_subdomain do      
      assert_difference "Message.all.reload.size", +1 do
        email = create_inbound_email_from_fixture('email_with_multiple_recipients.eml')
        email.tap(&:route)
        assert Message.last.content
      end
    end
  end

  test 'emails are mapped into same threads if the subjects are same, recipients are same and the in-reply-to header is not present' do
    Apartment::Tenant.switch @restarone_subdomain do      
      perform_enqueued_jobs do
        assert_difference "MessageThread.all.reload.size" , +1 do        
          assert_difference "Message.all.reload.size", +2 do          
            subject_line = "Hello world!"
            receive_inbound_email_from_mail \
              to: '"Don Restarone" <restarone@restarone.solutions>',
              from: '"else" <else@example.com>',
              subject: subject_line,
              body: "Hello?"

            assert MessageThread.all.last.subject
            assert Message.last.from


            receive_inbound_email_from_mail \
              to: '"Don Restarone" <restarone@restarone.solutions>',
              from: '"else" <else@example.com>',
              subject: subject_line,
              body: "Hello?"
          end
        end
      end
    end
  end

  test 'emails are mapped into same threads if the subjects differ by standard prefixes for replies and email forwarding, recipients are same and the in-reply-to header is not present' do
    Apartment::Tenant.switch @restarone_subdomain do      
      perform_enqueued_jobs do
        assert_difference "MessageThread.all.reload.size" , +1 do        
          assert_difference "Message.all.reload.size", +2 do          
            subject_line = "Hello world!"
            receive_inbound_email_from_mail \
              to: '"Don Restarone" <restarone@restarone.solutions>',
              from: '"else" <else@example.com>',
              subject: subject_line,
              body: "Hello?"

            assert MessageThread.all.last.subject
            assert Message.last.from


            receive_inbound_email_from_mail \
              to: '"Don Restarone" <restarone@restarone.solutions>',
              from: '"else" <else@example.com>',
              subject: 'Fw: ' + subject_line,
              body: "Hello?"
          end
        end
      end
    end
  end

  test 'emails are mapped into different threads if the subjects differ by standard prefixed for replies and email forwarding but recipients are different and the in-reply-to header is not present' do
    Apartment::Tenant.switch @restarone_subdomain do      
      perform_enqueued_jobs do
        assert_difference "MessageThread.all.reload.size" , +2 do        
          assert_difference "Message.all.reload.size", +2 do          
            subject_line = "Hello world!"
            receive_inbound_email_from_mail \
              to: '"Don Restarone" <restarone@restarone.solutions>',
              from: '"else" <else@example.com>',
              subject: subject_line,
              body: "Hello?"

            assert MessageThread.all.last.subject
            assert Message.last.from


            receive_inbound_email_from_mail \
              to: '"Don Restarone" <restarone@restarone.solutions>',
              from: '"if.else" <if.else@example.com>',
              subject: subject_line,
              body: "Hello?"
          end
        end
      end
    end
  end

  test 'emails are mapped into different threads if the subjects are same but recipients are different and the in-reply-to header is not present' do
    Apartment::Tenant.switch @restarone_subdomain do      
      perform_enqueued_jobs do
        assert_difference "MessageThread.all.reload.size" , +2 do        
          assert_difference "Message.all.reload.size", +2 do          
            subject_line = "Hello world!"
            receive_inbound_email_from_mail \
              to: '"Don Restarone" <restarone@restarone.solutions>',
              from: '"else" <else@example.com>',
              subject: subject_line,
              body: "Hello?"

            assert MessageThread.all.last.subject
            assert Message.last.from


            receive_inbound_email_from_mail \
              to: '"Don Restarone" <restarone@restarone.solutions>',
              from: '"if.else" <if.else@example.com>',
              subject: subject_line,
              body: "Hello?"
          end
        end
      end
    end
  end

  test 'emails are mapped into same threads when the in-reply-to header refers to one of the email from the same thread' do
    Apartment::Tenant.switch @restarone_subdomain do      
      perform_enqueued_jobs do
        assert_difference "MessageThread.all.reload.size" , +1 do        
          assert_difference "Message.all.reload.size", +2 do          
            subject_line = "Hello world!"
            receive_inbound_email_from_mail \
              to: '"Don Restarone" <restarone@restarone.solutions>',
              from: '"else" <else@example.com>',
              subject: subject_line,
              body: "Hello?"
            assert MessageThread.all.last.subject
            assert Message.last.from

            receive_inbound_email_from_mail \
              to: '"Don Restarone" <restarone@restarone.solutions>',
              from: '"else" <else@example.com>',
              subject: subject_line,
              body: "Hello?",
              'in-reply-to': "<#{Message.last.email_message_id}>"
          end
        end
    
        assert_no_difference "MessageThread.all.reload.size" do        
          assert_difference "Message.all.reload.size", +2 do
            receive_inbound_email_from_mail \
              to: '"Don Restarone" <restarone@restarone.solutions>',
              from: '"else" <else@example.com>',
              subject: 'subject_line',
              body: "Hello?",
              'in-reply-to': "<#{Message.last.email_message_id}>"

            receive_inbound_email_from_mail \
              to: '"Don Restarone" <restarone@restarone.solutions>',
              from: '"else" <else@example.com>',
              subject: 'subject_line 22',
              body: "Hello?",
              'in-reply-to': "<#{Message.last.email_message_id}>"
          end
        end
      end
    end
  end

  test 'emails are mapped into same threads when the in-reply-to header refers to one of the email from the same thread even if the subject and recipients are different' do
    Apartment::Tenant.switch @restarone_subdomain do      
      perform_enqueued_jobs do
        assert_difference "MessageThread.all.reload.size" , +1 do        
          assert_difference "Message.all.reload.size", +2 do          
            subject_line = "Hello world!"
            receive_inbound_email_from_mail \
              to: '"Don Restarone" <restarone@restarone.solutions>',
              from: '"else" <else@example.com>',
              subject: subject_line,
              body: "Hello?"
            assert MessageThread.all.last.subject
            assert Message.last.from

            receive_inbound_email_from_mail \
              to: '"Don Restarone" <restarone@restarone.solutions>',
              from: '"if.else" <if.else@example.com>',
              subject: 'Test: ' + subject_line,
              body: "Hello?",
              'in-reply-to': "<#{Message.last.email_message_id}>"
          end
        end
    
        assert_no_difference "MessageThread.all.reload.size" do        
          assert_difference "Message.all.reload.size", +2 do
            receive_inbound_email_from_mail \
              to: '"Don Restarone" <restarone@restarone.solutions>',
              from: '"else" <else@example.com>',
              subject: 'subject_line',
              body: "Hello?",
              'in-reply-to': "<#{Message.last.email_message_id}>"

            receive_inbound_email_from_mail \
              to: '"Don Restarone" <restarone@restarone.solutions>',
              from: '"when.else" <when.else@example.com>',
              subject: 'subject_line 22',
              body: "Hello?",
              'in-reply-to': "<#{Message.last.email_message_id}>"
          end
        end
      end
    end
  end

  # This is how github sends email notifications.
  test 'emails are mapped into same threads when the in-reply-to header refers to a different non-existent email message-id but the subject and recipients are same' do
    in_reply_to = "<restarone/violet_rails/test_email/123@github.com>"
    subject_line = "Hello world!"

    Apartment::Tenant.switch @restarone_subdomain do      
      perform_enqueued_jobs do
        assert_difference "MessageThread.all.reload.size" , +1 do        
          assert_difference "Message.all.reload.size", +2 do          
            receive_inbound_email_from_mail \
              to: '"Don Restarone" <restarone@restarone.solutions>',
              from: '"Violet Rails" <notifications@github.com>',
              subject: subject_line,
              body: "Hello?",
              'in-reply-to': in_reply_to,
              references: in_reply_to

            assert MessageThread.all.last.subject
            assert Message.last.from

            receive_inbound_email_from_mail \
              to: '"Don Restarone" <restarone@restarone.solutions>',
              from: '"Violet Rails" <notifications@github.com>',
              subject: 'Re: ' + subject_line,
              body: "Hello?",
              'in-reply-to': in_reply_to,
              references: in_reply_to
          end
        end
    
        assert_no_difference "MessageThread.all.reload.size" do        
          assert_difference "Message.all.reload.size", +2 do
            receive_inbound_email_from_mail \
              to: '"Don Restarone" <restarone@restarone.solutions>',
              from: '"Violet Rails" <notifications@github.com>',
              subject: 'FWD: ' + subject_line,
              body: "Hello?",
              'in-reply-to': in_reply_to,
              references: in_reply_to

            receive_inbound_email_from_mail \
              to: '"Don Restarone" <restarone@restarone.solutions>',
              from: '"Violet Rails" <notifications@github.com>',
              subject: 're: ' + subject_line,
              body: "Hello?",
              'in-reply-to': in_reply_to,
              references: in_reply_to
          end
        end
      end
    end
  end

  test "new message in thread sets thread unread: true" do
    #  todo test https://github.com/restarone/violet_rails/blob/57739a34ea8927ba222a42d372908a82e35de8cf/app/mailboxes/e_mailbox.rb
  end

  test "when sent with calendar invite" do
    Apartment::Tenant.switch @restarone_subdomain do      
      assert_difference "Message.all.reload.size", +1 do
        assert_difference "Meeting.all.reload.size", +1 do
          email = create_inbound_email_from_fixture('email_with_calendar_invite.eml')
          email.tap(&:route)
        end  
      end
    end
  end
end
