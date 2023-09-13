class Meeting < ApplicationRecord
  validates :status, inclusion: { in: ['pending', 'confirmed', 'maybe']  }
end
