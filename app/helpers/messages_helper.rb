module MessagesHelper
  # Extract the visible email content from HTML, removing meta tags, style tags, etc.
  # This is used to display email content in the message thread view and email sending
  def render_email_content(message)
    return '' if message.content.blank?
    
    # Use to_s to preserve ActionText attachments
    html_content = message.content.to_s
    
    # Parse the HTML
    doc = Nokogiri::HTML.fragment(html_content)
    
    # Remove the trix-content wrapper div if present (do this first)
    trix_div = doc.at_css('div.trix-content')
    if trix_div
      # Replace the trix-content div with its children
      trix_div.replace(trix_div.children.to_html)
      # Re-parse after removing trix wrapper
      doc = Nokogiri::HTML.fragment(doc.to_html)
    end
    
    # Remove meta tags, style tags, title, and link tags
    doc.css('meta').remove
    doc.css('style').remove
    doc.css('title').remove
    doc.css('link').remove
    
    # Get the HTML string
    result = doc.to_html
    
    # Remove leading text nodes that appear before the first HTML tag
    # This handles orphaned text like "My Email" from the title tag
    # Match any text at the beginning that comes before the first < character
    result = result.sub(/\A([^<]*?)(<)/, '\2')
    
    result.html_safe
  end
end
