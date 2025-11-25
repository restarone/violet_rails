require 'test_helper'

class MessagesHelperTest < ActionView::TestCase
  setup do
    @subdomain = subdomains(:public)
    Apartment::Tenant.switch @subdomain.name do
      @message_thread = MessageThread.create!(
        unread: true,
        subject: 'Test Email',
        recipients: ['test@example.com']
      )
    end
  end

  # Test: Normal case with meta, style, title, and link tags
  test 'removes meta, style, title, and link tags from email content' do
    html_content = <<~HTML
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>My Email</title>
      <link href="https://fonts.googleapis.com/css?family=Inter:400" rel="stylesheet">
      <style type="text/css">
        .test-class { color: red; }
      </style>
      <div class="test-class">Test content</div>
    HTML

    Apartment::Tenant.switch @subdomain.name do
      message = @message_thread.messages.create!(content: html_content)
      result = render_email_content(message)

      # Verify meta, style, title, and link tags are removed
      refute_match(/<meta/, result)
      refute_match(/<style/, result)
      refute_match(/<title/, result)
      refute_match(/<link/, result)

      # Verify the actual content is present
      assert_match(/Test content/, result)
      assert_match(/<div/, result)
    end
  end

  # Test: Content with only body HTML (no head tags)
  test 'returns content as-is when no head tags are present' do
    html_content = <<~HTML
      <div class="email-body">
        <h1>Welcome</h1>
        <p>This is a test email.</p>
      </div>
    HTML

    Apartment::Tenant.switch @subdomain.name do
      message = @message_thread.messages.create!(content: html_content)
      result = render_email_content(message)

      # Verify content is present
      assert_match(/Welcome/, result)
      assert_match(/This is a test email/, result)
      assert_match(/<div/, result)
      assert_match(/<h1/, result)
      assert_match(/<p/, result)
    end
  end

  # Test: Empty message content
  test 'returns empty string when message content is blank' do
    Apartment::Tenant.switch @subdomain.name do
      message = @message_thread.messages.create!(content: '')
      result = render_email_content(message)

      assert_equal '', result
    end
  end

  # Test: Message with nil content
  test 'returns empty string when message content is nil' do
    Apartment::Tenant.switch @subdomain.name do
      message = @message_thread.messages.new
      # Don't set content, it will be nil
      message.save(validate: false)
      
      result = render_email_content(message)

      assert_equal '', result
    end
  end

  # Test: Complex email with tables and inline styles
  test 'preserves tables and inline styles while removing head tags' do
    html_content = <<~HTML
      <meta charset="utf-8">
      <style>body { margin: 0; }</style>
      <table cellpadding="0" cellspacing="0" border="0" width="100%">
        <tr>
          <td align="center" style="background-color: #ffffff;">
            <h1 style="color: #333;">Hello World</h1>
          </td>
        </tr>
      </table>
    HTML

    Apartment::Tenant.switch @subdomain.name do
      message = @message_thread.messages.create!(content: html_content)
      result = render_email_content(message)

      # Verify meta and style tags are removed
      refute_match(/<meta/, result)
      refute_match(/<style/, result)

      # Verify table structure is preserved
      assert_match(/<table/, result)
      assert_match(/<tr/, result)
      assert_match(/<td/, result)

      # Verify inline styles are preserved
      assert_match(/background-color: #ffffff/, result)
      assert_match(/color: #333/, result)

      # Verify content is present
      assert_match(/Hello World/, result)
    end
  end

  # Test: Multiple style tags
  test 'removes all style tags when multiple are present' do
    html_content = <<~HTML
      <style>body { margin: 0; }</style>
      <div>Content 1</div>
      <style>.class1 { color: blue; }</style>
      <div>Content 2</div>
      <style>.class2 { color: green; }</style>
      <div>Content 3</div>
    HTML

    Apartment::Tenant.switch @subdomain.name do
      message = @message_thread.messages.create!(content: html_content)
      result = render_email_content(message)

      # Verify all style tags are removed
      refute_match(/<style/, result)
      refute_match(/body \{ margin: 0; \}/, result)
      refute_match(/\.class1/, result)
      refute_match(/\.class2/, result)

      # Verify content is present
      assert_match(/Content 1/, result)
      assert_match(/Content 2/, result)
      assert_match(/Content 3/, result)
    end
  end

  # Test: Nested tags (style inside other tags)
  test 'removes style tags even when nested' do
    html_content = <<~HTML
      <div>
        <style>.nested { color: red; }</style>
        <p>Nested content</p>
      </div>
    HTML

    Apartment::Tenant.switch @subdomain.name do
      message = @message_thread.messages.create!(content: html_content)
      result = render_email_content(message)

      # Verify style tag is removed
      refute_match(/<style/, result)
      refute_match(/\.nested/, result)

      # Verify content and structure are preserved
      assert_match(/Nested content/, result)
      assert_match(/<div/, result)
      assert_match(/<p/, result)
    end
  end

  # Test: Email with images and links
  test 'preserves images and links while removing head tags' do
    html_content = <<~HTML
      <meta name="viewport" content="width=device-width">
      <style>img { max-width: 100%; }</style>
      <a href="https://example.com">
        <img src="https://example.com/logo.png" alt="Logo" width="100">
      </a>
      <p>Click the logo above</p>
    HTML

    Apartment::Tenant.switch @subdomain.name do
      message = @message_thread.messages.create!(content: html_content)
      result = render_email_content(message)

      # Verify meta and style tags are removed
      refute_match(/<meta/, result)
      refute_match(/<style/, result)

      # Verify images and links are preserved
      assert_match(/<a href="https:\/\/example\.com"/, result)
      assert_match(/<img/, result)
      assert_match(/src="https:\/\/example\.com\/logo\.png"/, result)
      assert_match(/alt="Logo"/, result)
      assert_match(/width="100"/, result)

      # Verify content is present
      assert_match(/Click the logo above/, result)
    end
  end

  # Test: Real Revolvapp-style email
  test 'handles Revolvapp-style email with all head tags' do
    html_content = <<~HTML
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Newsletter</title>
      <link href="https://fonts.googleapis.com/css?family=Inter:400,700" rel="stylesheet">
      <style type="text/css">
        #outlook a{padding:0}
        .ExternalClass{width:100%}
        body{margin:0;padding:0}
      </style>
      <table cellpadding="0" cellspacing="0" border="0" width="600">
        <tr>
          <td align="center" style="padding: 40px;">
            <h1>Newsletter Title</h1>
            <p>Newsletter content goes here.</p>
          </td>
        </tr>
      </table>
    HTML

    Apartment::Tenant.switch @subdomain.name do
      message = @message_thread.messages.create!(content: html_content)
      result = render_email_content(message)

      # Verify all head tags are removed
      refute_match(/<meta/, result)
      refute_match(/<title/, result)
      refute_match(/<link/, result)
      refute_match(/<style/, result)

      # Verify CSS content is not visible
      refute_match(/#outlook a\{padding:0\}/, result)
      refute_match(/ExternalClass/, result)

      # Verify email structure is preserved
      assert_match(/<table/, result)
      assert_match(/Newsletter Title/, result)
      assert_match(/Newsletter content goes here/, result)

      # Verify inline styles are preserved
      assert_match(/padding: 40px/, result)
    end
  end

  # Test: HTML with special characters
  test 'handles HTML with special characters correctly' do
    html_content = <<~HTML
      <style>.special { content: "< > & \""; }</style>
      <div>
        <p>Special chars: &lt; &gt; &amp; &quot;</p>
        <p>Symbols: © ® ™</p>
      </div>
    HTML

    Apartment::Tenant.switch @subdomain.name do
      message = @message_thread.messages.create!(content: html_content)
      result = render_email_content(message)

      # Verify style tag is removed
      refute_match(/<style/, result)

      # Verify special characters are preserved (Nokogiri decodes some entities)
      assert_match(/&lt;/, result)
      assert_match(/&gt;/, result)
      assert_match(/&amp;/, result)
      # Note: Nokogiri decodes &quot; to " when parsing, so we check for the actual character
      assert_match(/"/, result)
      assert_match(/©/, result)
      assert_match(/®/, result)
      assert_match(/™/, result)
    end
  end

  # Test: Return value is html_safe
  test 'returns html_safe string' do
    html_content = '<div>Test</div>'

    Apartment::Tenant.switch @subdomain.name do
      message = @message_thread.messages.create!(content: html_content)
      result = render_email_content(message)

      assert result.html_safe?
    end
  end

  # Test: Whitespace handling
  test 'handles whitespace correctly' do
    html_content = <<~HTML
      <meta charset="utf-8">
      
      <style>
        body { margin: 0; }
      </style>
      
      <div>
        <p>Content with whitespace</p>
      </div>
    HTML

    Apartment::Tenant.switch @subdomain.name do
      message = @message_thread.messages.create!(content: html_content)
      result = render_email_content(message)

      # Verify tags are removed
      refute_match(/<meta/, result)
      refute_match(/<style/, result)

      # Verify content is present
      assert_match(/Content with whitespace/, result)
    end
  end

  # Test: Self-closing tags
  test 'handles self-closing meta and link tags' do
    html_content = <<~HTML
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width" />
      <link rel="stylesheet" href="style.css" />
      <div>Content</div>
    HTML

    Apartment::Tenant.switch @subdomain.name do
      message = @message_thread.messages.create!(content: html_content)
      result = render_email_content(message)

      # Verify self-closing tags are removed
      refute_match(/<meta/, result)
      refute_match(/<link/, result)

      # Verify content is present
      assert_match(/Content/, result)
    end
  end

  # Test: Comments in HTML
  test 'preserves HTML comments while removing head tags' do
    html_content = <<~HTML
      <meta charset="utf-8">
      <!-- This is a comment -->
      <style>.test { color: red; }</style>
      <div>
        <!-- Another comment -->
        <p>Content</p>
      </div>
    HTML

    Apartment::Tenant.switch @subdomain.name do
      message = @message_thread.messages.create!(content: html_content)
      result = render_email_content(message)

      # Verify head tags are removed
      refute_match(/<meta/, result)
      refute_match(/<style/, result)

      # Verify comments are preserved
      assert_match(/<!-- This is a comment -->/, result)
      assert_match(/<!-- Another comment -->/, result)

      # Verify content is present
      assert_match(/Content/, result)
    end
  end
end
