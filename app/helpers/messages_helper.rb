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
    
    # Remove HTML comments (like <!--[if mso]>)
    doc.xpath('//comment()').remove
    
    # Clean up: remove empty text nodes and whitespace-only nodes at the start
    cleaned_children = []
    found_real_content = false
    
    doc.children.each do |node|
      # Skip whitespace-only text nodes before real content
      if node.text? && !found_real_content
        next if node.text.strip.empty?
        # Skip standalone text nodes before first element (like "My Email")
        next unless node.text.strip.empty?
      end
      
      # Mark that we found real content when we hit an element
      found_real_content = true if node.element?
      
      cleaned_children << node if found_real_content
    end
    
    # Rebuild the document with cleaned children
    result = cleaned_children.map(&:to_html).join
    
    result.html_safe
  end
end
