class RichTextBodyValidator < ActiveModel::Validator
  def validate(record)
    if record.body.blank?
      record.errors.add :body, " can't be blank"
    end
  end
end
class ForumPost < ApplicationRecord
  include ActiveModel::Validations

  belongs_to :forum_thread, counter_cache: true, touch: true
  belongs_to :user, optional: true

  validates :body, presence: true
  validates_with RichTextBodyValidator
  has_rich_text :body
  has_one :body, class_name: 'ActionText::RichText', as: :record
  scope :sorted, -> { order(:created_at) }

  after_update :solve_forum_thread, if: :solved?

  
  def solve_forum_thread
    forum_thread.update(solved: true)
  end
end