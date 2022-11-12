class ForumCategory < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  scope :sorted, -> { order(name: :asc) }

  validates :name, :slug, :color, presence: true

  before_save :set_slug

  def color
    colour = super
    colour.start_with?("#") ? colour : "##{colour}"
  end

  private 
  def set_slug
    self.slug = self.name&.downcase&.gsub(' ', '-') if self.slug.blank?
  end
end
