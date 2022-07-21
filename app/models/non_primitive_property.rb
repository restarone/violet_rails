class NonPrimitiveProperty < ApplicationRecord 
  belongs_to :api_resource, optional: true
  belongs_to :api_namespace, optional: true

  enum field_type: { file: 0, richtext: 1 }

  has_rich_text :content
  has_one_attached :attachment

  validates_presence_of :label

  def file_url
    Rails.application.routes.url_helpers.rails_blob_url(self.attachment, subdomain:  Apartment::Tenant.current, host: ENV['APP_HOST']) if self.file?
  end
end
