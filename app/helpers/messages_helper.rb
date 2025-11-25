module MessagesHelper
    # Extract the visible email content from HTML, removing meta tags, style tags, etc.
    # This is used to display email content in the message thread view
 def render_email_content(message)
    return '' if message.content.blank?
    
    html_content = message.content.body.to_html
    
    # Parse the HTML
    doc = Nokogiri::HTML.fragment(html_content)
    
    # Remove meta tags, style tags, title, and link tags
    doc.css('meta, style, title, link').remove
    
    # Return the sanitized HTML
    doc.to_html.html_safe
  end
end
