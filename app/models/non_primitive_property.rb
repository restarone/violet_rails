class NonPrimitiveProperty < ApplicationRecord
  belongs_to :api_resource, optional: true
  belongs_to :api_namespace, optional: true

  enum field_type: { file: 0, richtext: 1 }

  has_rich_text :content
  has_one_attached :attachment

  validates_presence_of :label

  def file_url
    if self.file? && self.attachment.attached?
      if Current.is_api_html_renderer_request
        # ActiveStorage::Current.host is only set in controller's context
        ActiveStorage::Current.host = Rails.application.routes.url_helpers.root_url if ActiveStorage::Current.host.blank?
        self.attachment.blob.url(expires_in: 1.week)
      else
        Rails.application.routes.url_helpers.rails_blob_url(self.attachment)
      end
    end
  end
end
