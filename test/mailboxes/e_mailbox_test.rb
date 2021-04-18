require "test_helper"

class EMailboxTest < ActionMailbox::TestCase

  setup do
    @restarone_subdomain = Subdomain.find_by(name: 'restarone').name
    Apartment::Tenant.switch @restarone_subdomain do
      EmailAlias.all.destroy_all
      @user = User.first
      @user.update(can_manage_email: true)
      @user.email_aliases.create!(name: 'hello')
    end
  end

  test "inbound mail routes to correct schema" do
    Apartment::Tenant.switch 'restarone' do 
      receive_inbound_email_from_mail \
        to: '"Don Restarone" <hello@restarone.restarone.solutions>',
        from: '"else" <else@example.com>',
        subject: "Hello world!",
        body: "Hello?"
    end
  end

  test 'direct attachment' do
    Apartment::Tenant.switch 'restarone' do      
      mail = Mail.new(
        from: 'else@example.com',
        to: 'hello@restarone.restarone.solutions',
        subject: 'Logo',
        body: 'Hi, See the logo attached.',
      )
      mail.add_file filename: 'template.eml', content: StringIO.new('Sample Logo')
      create_inbound_email_from_source(mail.to_s).tap(&:route)
    end
  end

  test "inbound multipart mail routes to correct schema" do
    Apartment::Tenant.switch 'restarone' do      
      create_inbound_email_from_mail do      
        from '"else" <else@example.com>'
        to '"Don Restarone" <hello@restarone.restarone.solutions>'
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
    Apartment::Tenant.switch 'restarone' do      
      assert_changes "ActiveStorage::Blob.all.reload.size" do
        email = create_inbound_email_from_fixture('multipart-with-files.eml')
        email.tap(&:route)
        assert Message.last.content
      end
    end
  end

  test "from video attachment" do
    Apartment::Tenant.switch 'restarone' do      
      assert_changes "ActiveStorage::Blob.all.reload.size" do
        email = create_inbound_email_from_fixture('with-video-attachment.eml')
        email.tap(&:route)
        assert Message.last.content
      end
    end
  end
end
