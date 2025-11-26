# Configure ActionText to allow style tags and attributes
# This is necessary for email templates (e.g., Revolvapp) that include CSS styles and tables
Rails.application.config.to_prepare do
  # Allow the style attribute on all tags
  ActionText::ContentHelper.allowed_attributes.add('style')
  ActionText::ContentHelper.allowed_attributes.add('cellpadding')
  ActionText::ContentHelper.allowed_attributes.add('cellspacing')
  ActionText::ContentHelper.allowed_attributes.add('border')
  ActionText::ContentHelper.allowed_attributes.add('width')
  ActionText::ContentHelper.allowed_attributes.add('align')
  ActionText::ContentHelper.allowed_attributes.add('valign')
  ActionText::ContentHelper.allowed_attributes.add('bgcolor')
  
  # Allow the style tag itself
  ActionText::ContentHelper.allowed_tags.add('style')
  
  # Allow table-related tags for email templates
  ActionText::ContentHelper.allowed_tags.add('table')
  ActionText::ContentHelper.allowed_tags.add('tbody')
  ActionText::ContentHelper.allowed_tags.add('thead')
  ActionText::ContentHelper.allowed_tags.add('tfoot')
  ActionText::ContentHelper.allowed_tags.add('tr')
  ActionText::ContentHelper.allowed_tags.add('td')
  ActionText::ContentHelper.allowed_tags.add('th')
end
