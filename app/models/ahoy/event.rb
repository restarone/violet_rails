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

  scope :filter_records_with_video_details_missing, -> {
    self
      .where(
        "(properties ->> 'watch_time') IS NOT NULL"\
        " AND (properties ->> 'video_start') IS NOT NULL"\
        " AND (properties ->> 'total_duration') IS NOT NULL"\
        " AND (properties ->> 'resource_id') IS NOT NULL"
      )
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

  def self.total_watch_time_for_video_events
    self.pluck(Arel.sql("SUM((#{Ahoy::Event.table_name}.properties ->> 'watch_time')::bigint)")).sum
  end

  def self.total_views_for_video_events
    self.pluck(Arel.sql("SUM(CASE WHEN (#{Ahoy::Event.table_name}.properties ->> 'video_start')::boolean THEN 1 ELSE 0 END)")).sum
  end

  def self.avg_view_duration_for_video_events
    self.total_watch_time_for_video_events.to_f / (self.total_views_for_video_events.nonzero? || 1)
  end

  def self.avg_view_percentage_for_video_events
    self.pluck(Arel.sql("((properties ->> 'watch_time')::float / (properties ->> 'total_duration')::float) * 100")).sum / (self.total_views_for_video_events.nonzero? || 1)
  end

  def self.top_three_videos_details
    # previous_video_events = Ahoy::Event.where(id: previous_video_event_ids).load

    # Ahoy::Event
    #   .where(id: video_event_ids)
    self
      .with_api_resource
      .group(:resource_id)
      .reorder("SUM(is_viewed) DESC", "total_watch_time DESC")
      .select(:resource_id,
        "SUM(watch_time)::INT AS total_watch_time",
        "SUM(is_viewed) AS total_views",
        "MAX(total_duration)::float AS duration",
        "json_agg(ahoy_events.name) AS names",
        "json_agg(namespace_id) AS namespace_ids")
      .limit(3)
      .as_json
      .map(&:with_indifferent_access)
      .each do |video_event|
        # previous_period_event_ids = previous_video_events.jsonb_search(:properties, { resource_id: video_event[:resource_id] }).pluck(:id)
        api_resource = ApiResource.find_by(id: video_event[:resource_id])

        video_event[:name] = video_event[:names].uniq.first
        video_event[:duration] = video_event[:duration] || 0
        video_event[:namespace_id] = video_event[:namespace_ids].uniq.first
        # video_event[:previous_period_total_views] = total_views(previous_period_event_ids)
        # video_event[:previous_period_total_watch_time] = total_watch_time(previous_period_event_ids)
        video_event[:resource_title] = api_resource&.properties.dig(api_resource&.api_namespace.analytics_metadata&.dig("title")) || "Resource Id: #{video_event[:resource_id]}"
        video_event[:resource_author] = api_resource&.properties.dig(api_resource&.api_namespace.analytics_metadata&.dig("author"))
        video_event[:resource_image] = api_resource&.non_primitive_properties.find_by(field_type: "file", label: api_resource&.api_namespace.analytics_metadata&.dig("thumbnail"))&.file_url

        video_event.delete(:names)
        video_event.delete(:namespace_ids)
        video_event.delete(:id)
      end
  end

  def self.total_views_and_watch_time_detals_for_previous_video_events(resource_ids)
    # byebug
    self
      .with_api_resource
      .where('api_resourced_events.resource_id': resource_ids)
      .group(:resource_id)
      .select(:resource_id,
        "SUM(watch_time)::INT AS previous_period_total_watch_time",
        "SUM(is_viewed) AS previous_period_total_views",
        "MAX(total_duration)::float AS duration")
      .as_json
      .map(&:with_indifferent_access)
  end

  def self.page_visit_chart_data_for_page_visit_events(date_range, grouping_data)
    # period, format = split_into(start_date, end_date)
    chart_data = []

    # Ahoy::Event
    #   .joins(:visit)
    #   .where(id: event_ids)
    self
      .where.not(visit: {device_type: nil})
      .group("visit.device_type")
      .group_by_period(grouping_data[:period], :time, range: date_range, format: grouping_data[:format])
      .size
      .group_by {|k, v| k.first}
      .each do |k, v|
        chart_data << {
          name: k,
          data: v.map {|item| [item.first.last, item.last]}.to_h
        }
      end
      # .map do |k,  v| 
      #   {
      #     name: k,
      #     data: v.map {|item| [item.first.last, item.last]}.to_h
      #   }
      # end 

      chart_data
  end 

  def self.visitors_chart_data_for_page_visit_events
    # visitors_by_token = Ahoy::Event.joins(:visit).where(id: event_ids).group(:visitor_token).size
    visitors_by_token = self.group(:visitor_token).size
    recurring_visitors = visitors_by_token.values.count { |v| v > 1 }
    single_time_visitors = visitors_by_token.keys.count - recurring_visitors
    {"Single time visitor": single_time_visitors, "Recurring visitors" => recurring_visitors  }
  end
end