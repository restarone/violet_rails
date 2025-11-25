# Configure ActionText to allow style tags and attributes
# This is necessary for email templates (e.g., Revolvapp) that include CSS styles
Rails.application.config.to_prepare do
  # Allow the style attribute on all tags
  ActionText::ContentHelper.allowed_attributes.add('style')
  
  # Allow the style tag itself
  ActionText::ContentHelper.allowed_tags.add('style')
end
