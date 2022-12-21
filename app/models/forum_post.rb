class ForumPost < ApplicationRecord
  belongs_to :forum_thread, counter_cache: true, touch: true
  belongs_to :user, optional: true

  validates :body, presence: true, unless: :has_attachment
  has_rich_text :body

  scope :sorted, -> { order(:created_at) }

  after_update :solve_forum_thread, if: :solved?

  def has_attachment
    body.body.attachments.length > 0
  end

  def solve_forum_thread
    forum_thread.update(solved: true)
  end
end