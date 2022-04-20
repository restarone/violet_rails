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
    Apartment::Tenant.switch @restarone_subdomain do 
      assert_difference "ApiResource.count", +1 do      
        receive_inbound_email_from_mail \
          to: '"Don Restarone" <restarone@restarone.solutions>',
          from: '"else" <else@example.com>',
          subject: "Hello world!",
          body: "Hello?"
      end
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

  test 'message threads' do
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
    
        assert_no_difference "MessageThread.all.reload.size" do        
          assert_difference "Message.all.reload.size", +2 do
            receive_inbound_email_from_mail \
            to: '"Don Restarone" <restarone@restarone.solutions>',
            from: '"else" <else@example.com>',
            subject: 'subject_line',
            body: "Hello?"

            receive_inbound_email_from_mail \
              to: '"Don Restarone" <restarone@restarone.solutions>',
              from: '"else" <else@example.com>',
              subject: 'subject_line 22',
              body: "Hello?"
          end
        end
      end
    end
  end
end
