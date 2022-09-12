class ForumPost < ApplicationRecord
  belongs_to :forum_thread, counter_cache: true, touch: true
  belongs_to :user, optional: true

  validates :body, presence: true
  has_rich_text :body
  # Ref: https://stackoverflow.com/questions/59575397/search-text-in-actiontext-attribute/60138981#60138981
  has_one :action_text_rich_text, class_name: 'ActionText::RichText', as: :record
  scope :sorted, -> { order(:created_at) }

  after_update :solve_forum_thread, if: :solved?

  def solve_forum_thread
    forum_thread.update(solved: true)
  end
end