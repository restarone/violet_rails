class ForumPost < ApplicationRecord
  belongs_to :forum_thread, counter_cache: true, touch: true
  belongs_to :user, optional: true

  validates :body, presence: true
  has_rich_text :body
  has_one :body, class_name: 'ActionText::RichText', as: :record
  scope :sorted, -> { order(:created_at) }

  after_update :solve_forum_thread, if: :solved?

  def solve_forum_thread
    forum_thread.update(solved: true)
  end
end