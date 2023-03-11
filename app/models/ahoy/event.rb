class Ahoy::Event < ApplicationRecord
  include Ahoy::QueryMethods
  include JsonbSearch::Searchable

  SYSTEM_EVENTS = {
    'comfy-blog-page-visit'=> 0,
    'comfy-cms-page-update'=> 1,
    'comfy-cms-page-visit'=> 2,
    'comfy-cms-file-update'=> 3,
    'subdomain-user-update'=> 4,
    'subdomain-email-visit'=> 5,
    'subdomain-forum-post-update'=> 6,
    'subdomain-forum-thread-visit'=> 7,
    'api-resource-create' => 8
  }

  EVENT_CATEGORIES = {
    page_visit: 'page_visit',
    click: 'click',
    video_view: 'video_view', 
    form_submit: 'form_submit', 
    section_view: 'section_view'
  }

  self.table_name = "ahoy_events"

  belongs_to :visit
  belongs_to :user, optional: true

  scope :with_label , -> {
    # Build a subquery SQL
    subquery = self.unscoped.select("(case when #{table_name}.properties->>'label' is not NULL then #{table_name}.properties->>'label' else #{table_name}.name end) as label, #{table_name}.id").to_sql

    # join the subquery to base model
    joins("INNER JOIN (#{subquery}) as labelled_events ON labelled_events.id = #{table_name}.id")
  }

  scope :with_api_resource , -> {
    # Build a subquery SQL
    subquery = self
                .unscoped
                .joins("INNER JOIN #{ApiResource.table_name} ON ahoy_events.properties->>'resource_id' IS NOT NULL AND (ahoy_events.properties ->> 'resource_id')::int = #{ApiResource.table_name}.id")
                .select(
                  "(#{self.table_name}.properties ->> 'resource_id')::int AS resource_id",
                  "#{self.table_name}.id",
                  "#{ApiResource.table_name}.api_namespace_id AS namespace_id",
                  "(#{self.table_name}.properties ->> 'watch_time')::bigint AS watch_time",
                  "round((#{self.table_name}.properties->>'total_duration')::numeric, 3) AS total_duration",
                  "CASE WHEN (#{self.table_name}.properties ->> 'video_start')::boolean THEN 1 ELSE 0 END AS is_viewed",
                  )
                  .to_sql

    # join the subquery to base model
    joins("INNER JOIN (#{subquery}) as api_resourced_events ON api_resourced_events.id = #{table_name}.id")
  }

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

  def label
    properties["label"] || name
  end

  def self.delete_specific_events_and_associated_visits(delete_events: false, event_type:)
    begin
      ActiveRecord::Base.transaction do
        raise 'System defined events and their visits cannot be deleted.' if Ahoy::Event::SYSTEM_EVENTS.keys.include?(event_type)

        events = Ahoy::Event.where(name: event_type)
        associated_visits = Ahoy::Visit.joins(:events).where(ahoy_events: { id: events }).distinct

        associated_visits.destroy_all
        events.destroy_all if delete_events

        message = delete_events ? "All #{event_type} events and its associated visits has been deleted successfully." : "All associated visits of #{event_type} events has been deleted successfully."

        { success: true, message: message }
      end
    rescue => e
      error_message = delete_events ? "Deleting specific events failed due to: #{e.message}" : "Deleting associated visits of specific events failed due to: #{e.message}"

      { success: false, message: e.message }
    end
  end
end