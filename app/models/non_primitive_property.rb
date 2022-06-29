class NonPrimitiveProperty < ApplicationRecord
  belongs_to :api_resource, optional: true
  belongs_to :api_namespace, optional: true

  enum field_type: { file: 0, richtext: 1 }

  has_rich_text :content
  has_one_attached :attachment

  validates_presence_of :label

  before_save :reset_allow_attachments

  private

  def reset_allow_attachments
    self.allow_attachments = true if self.field_type != 'richtext' && !self.allow_attachments
  end
end
