class Ahoy::Event < ApplicationRecord
  include Ahoy::QueryMethods

  SYSTEM_EVENTS = { 'comfy-blog-page-visit'=> 0, 'comfy-cms-page-update'=> 1, 'comfy-cms-page-visit'=> 2, 'comfy-file-update'=> 3, 'comfy-user-update'=> 4, 'email-visit'=> 5, 'forum-post-update'=> 6, 'forum-thread-visit'=> 7 }

  self.table_name = "ahoy_events"

  belongs_to :visit
  belongs_to :user, optional: true

  # For events_list page, sorting on the grouped query
  # https://stackoverflow.com/a/35987240
  ransacker :count do
    Arel.sql('count')
  end

  ransacker :first_created_at do
    Arel.sql('first_created_at')
  end

  ransacker :distinct_name do
    Arel.sql('distinct_name')
  end
end