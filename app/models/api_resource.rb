class ApiResource < ApplicationRecord
  belongs_to :api_namespace

  has_many :non_primitive_properties, dependent: :destroy
  accepts_nested_attributes_for :non_primitive_properties, allow_destroy: true
end
