require "test_helper"

class EMailboxTest < ActionMailbox::TestCase
  test "inbound mail routes to correct schema" do
    receive_inbound_email_from_mail \
      to: '"Don Restarone" <restarone@restarone.solutions>',
      from: '"else" <else@example.com>',
      subject: "Hello world!",
      body: "Hello?"
  end

  test "inbound multipart mail routes to correct schema" do
    Apartment::Tenant.switch 'restarone' do      
      Mail::Message.any_instance.stubs(:multipart).returns(true)
      Mail::Message.any_instance.stubs(:html_part).returns(true)
      create_inbound_email_from_mail do      
        to '"Don Restarone" <restarone@restarone.solutions>'
        from '"else" <else@example.com>'
        subject "Hello world!"
        multipart true
        text_part do
          body "hello this is the body"
        end
        html_part do
          body "<h1>Please join us for a party at Bag End</h1>"
        end
      end 
    end
  end

  test "from file" do
    skip
    Apartment::Tenant.switch 'restarone' do      
      assert_difference "Message.all.reload.size", +1 do        
        Mail::Message.any_instance.stubs(:multipart).returns(true)
        Mail::Message.any_instance.stubs(:html_part).returns(true)
        create_inbound_email_from_fixture('template.eml')
      end
    end
  end
end
