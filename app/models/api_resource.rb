class ApiResource < ApplicationRecord
  belongs_to :api_namespace

  before_create :initialize_api_actions

  has_many :non_primitive_properties, dependent: :destroy
  accepts_nested_attributes_for :non_primitive_properties, allow_destroy: true

  has_many :api_actions, dependent: :destroy

  ransacker :properties do |_parent|
    Arel.sql("api_resources.properties::text") 
  end

  def initialize_api_actions
    api_namespace.api_actions.each do |action|
      api_actions.build(action.attributes.except("id", "created_at", "updated_at", "api_namespace_id", "lifecycle_message"))
    end
  end
end
