class NonPrimitiveProperty < ApplicationRecord
  belongs_to :api_resource, optional: true
  belongs_to :api_namespace, optional: true

  enum field_type: { file: 0, richtext: 1 }

  has_rich_text :content
  has_one_attached :attachment

  validates_presence_of :label

  def file_url
    if self.file? && self.attachment.attached?
      ActiveStorage::Current.host = Rails.application.routes.url_helpers.root_url(host: Subdomain.current.hostname) if ActiveStorage::Current.host.blank?
      self.attachment.blob.url(expires_in: 5.hours)
    end
  end
end
