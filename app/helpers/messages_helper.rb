module MessagesHelper
  # Extract the visible email content from HTML, removing meta tags, style tags, etc.
  # This is used to display email content in the message thread view and email sending
  def render_email_content(message)
    return '' if message.content.blank?
    
    # Use to_s to preserve ActionText attachments
    html_content = message.content.to_s
    
    # Parse the HTML
    doc = Nokogiri::HTML.fragment(html_content)
    
    # Detect if this is a Revolvapp email template by checking for characteristic tags
    # Revolvapp emails have meta, style, title, or link tags
    is_revolvapp_email = doc.css('meta, style, title, link').any?
    
    # Only remove the trix-content wrapper for Revolvapp emails
    # Regular Trix editor content needs the wrapper for proper CSS styling
    if is_revolvapp_email
      trix_div = doc.at_css('div.trix-content')
      if trix_div
        # Replace the trix-content div with its children
        trix_div.replace(trix_div.children.to_html)
        # Re-parse after removing trix wrapper
        doc = Nokogiri::HTML.fragment(doc.to_html)
      end
    end
    
    # Remove meta tags, style tags, title, and link tags (only present in Revolvapp emails)
    doc.css('meta').remove
    doc.css('style').remove
    doc.css('title').remove
    doc.css('link').remove
    
    # Get the HTML string
    result = doc.to_html
    
    # Remove leading text nodes that appear before the first HTML tag
    # This handles orphaned text like "My Email" from the title tag in Revolvapp emails
    # Only do this for Revolvapp emails to avoid affecting regular content
    if is_revolvapp_email
      result = result.sub(/\A([^<]*?)(<)/, '\2')
    end
    
    result.html_safe
  end
end
