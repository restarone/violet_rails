class ForumThread < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged

  belongs_to :forum_category
  belongs_to :user, optional: true
  has_many :forum_posts
  has_many :forum_subscriptions
  has_many :optin_subscribers, -> { where(forum_subscriptions: {subscription_type: :optin}) }, through: :forum_subscriptions, source: :user
  has_many :optout_subscribers, -> { where(forum_subscriptions: {subscription_type: :optout}) }, through: :forum_subscriptions, source: :user
  has_many :users, through: :forum_posts

  accepts_nested_attributes_for :forum_posts

  validates :forum_category, presence: true
  validates :title, presence: true
  validates_associated :forum_posts

  scope :pinned_first, -> { order(pinned: :desc) }
  scope :solved, -> { where(solved: true) }
  scope :sorted, -> { order(updated_at: :desc) }
  scope :unpinned, -> { where.not(pinned: true) }
  scope :unsolved, -> { where.not(solved: true) }
  scope :contains_title, ->(query) { where("title ILIKE ?", "%#{query}%") }
  scope :contains_body_skope, ->(query) { where("action_text_rich_texts.body  ILIKE ?", "%#{query}%") }
  scope :join_with_posts_and_rich_texts, -> {
    joins("INNER JOIN forum_posts ON forum_posts.forum_thread_id = forum_threads.id
		   INNER JOIN action_text_rich_texts ON action_text_rich_texts.id = forum_posts.id")
  }
  scope :contains_body, ->(query) { join_with_posts_and_rich_texts.contains_body_skope(query).distinct }
  scope :contains_either_title_or_body, ->(query) {
    # union of 2 active record relations throws error if one of them contains: limit, offset, distinct see: https://github.com/rails/rails/issues/24055
    join_with_posts_and_rich_texts.contains_body_skope(query).or(contains_title(query)).distinct
  }

  def mentioned_users
    forum_posts.map { |forum_post| forum_post.body.body.attachments.select{ |a| a.attachable.class == User }.map(&:attachable) }.flatten.uniq
  end
  
  def subscribed_users
    (users + optin_subscribers + mentioned_users).uniq - optout_subscribers
  end

  def subscription_for(user)
    return nil if user.nil?
    forum_subscriptions.find_by(user_id: user.id)
  end

  def subscribed?(user)
    return false if user.nil?

    subscription = subscription_for(user)

    if subscription.present?
      subscription.subscription_type == "optin"
    else
      forum_posts.where(user_id: user.id).any? || mentioned_users.include?(user)
    end
  end

  def toggle_subscription(user)
    subscription = subscription_for(user)
    if subscription.present?
      subscription.toggle!
    elsif forum_posts.where(user_id: user.id).any? || mentioned_users.include?(user)
      forum_subscriptions.create(user: user, subscription_type: "optout")
    else
      forum_subscriptions.create(user: user, subscription_type: "optin")
    end
  end

  def subscribed_reason(user)
    return I18n.t(".not_receiving_notifications") if user.nil?

    subscription = subscription_for(user)

    if subscription.present?
      if subscription.subscription_type == "optout"
        I18n.t(".ignoring_thread")
      elsif subscription.subscription_type == "optin"
        I18n.t(".receiving_notifications_because_subscribed")
      end
    elsif forum_posts.where(user_id: user.id).any?
      I18n.t(".receiving_notifications_because_posted")
    elsif mentioned_users.include?(user)
      I18n.t(".receiving_notifications_because_mentioned")
    else
      I18n.t(".not_receiving_notifications")
    end
  end

  # These are the users to notify on a new thread.
  def notify_users
    mentioned_users - User.forum_mods - [user]
  end
end