require "test_helper"

class EMailboxTest < ActionMailbox::TestCase
  test "inbound mail routes to correct schema" do
    receive_inbound_email_from_mail \
      to: '"Don Restarone" <restarone@restarone.solutions>',
      from: '"else" <else@example.com>',
      subject: "Hello world!",
      body: "Hello?"
  end

  test 'new way' do
    Apartment::Tenant.switch 'restarone' do      
      mail = Mail.new(
        from: 'else@example.com',
        to: 'restarone@restarone.solutions',
        subject: 'Logo',
        body: 'Hi, See the logo attached.',
      )
      mail.add_file filename: 'template.eml', content: StringIO.new('Sample Logo')
      create_inbound_email_from_source(mail.to_s).tap(&:route)
      byebug
    end
  end

  test "inbound multipart mail routes to correct schema" do
    skip
    Apartment::Tenant.switch 'restarone' do      
      email = create_inbound_email_from_mail do      
        to '"Don Restarone" <restarone@restarone.solutions>'
        from '"else" <else@example.com>'
        subject "Hello world!"
        text_part do
          body "hello this is the body"
        end
        html_part do
          body "<h1>Please join us for a party at Bag End</h1>"
        end
      end 

      receive_inbound_email_from_mail email
    end
  end

  test "from file" do
    skip
    Apartment::Tenant.switch 'restarone' do      
      Mail::Message.any_instance.stubs(:multipart).returns(true)
      Mail::Message.any_instance.stubs(:html_part).returns(true)
      email = create_inbound_email_from_fixture('template.eml')
      receive_inbound_email_from_mail email
    end
  end

  test "from multipart file" do
    skip
    Apartment::Tenant.switch 'restarone' do      
      Mail::Message.any_instance.stubs(:multipart).returns(true)
      Mail::Message.any_instance.stubs(:html_part).returns(true)
      email = create_inbound_email_from_fixture('multipart-with-files.eml')
      receive_inbound_email_from_mail email
    end
  end
end
