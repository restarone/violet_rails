class Meeting < ApplicationRecord
  STATUS_LIST = ['TENTATIVE', 'CONFIRMED', 'CANCELLED']
  # https://www.kanzaki.com/docs/ical/status.html

  validates :status, inclusion: { in: STATUS_LIST  }
end
