module DashboardHelper
  def redact_private_urls(url)
    should_exclude = false
    return if !url
    exclusions = Subdomain::PRIVATE_URL_PATHS
    exclusions.each do |exclusion|
      if url.include?(exclusion)
        should_exclude = true
      end
    end
    if should_exclude
      "private-system-url-redacted"
    else
      url
    end
  end

  def session_detail_title
    return 'Visit' if params[:id].blank?

    user_visit_count = Ahoy::Visit.where(user_id: params[:id]).where('started_at <= ?', @visit.started_at).size
    "Visit (#{user_visit_count})"
  end

  def page_visit_chart_data(page_visit_events, start_date, end_date)
    period, format = split_into(start_date, end_date)

    page_visit_events
      .where.not(visit: {device_type: nil})
      .group("visit.device_type")
      .group_by_period(period, :time, range: start_date..end_date, format: format)
      .size
      .group_by {|k, v| k.first}
      .map do |k,  v| 
        {
          name: k,
          data: v.map {|item| [item.first.last, item.last]}.to_h
        }
      end 
  end 
    
  def page_name(page_id)
    return 'Website' if page_id.blank?

    Comfy::Cms::Page.find_by(id: page_id)&.label
  end

  def visitors_chart_data(visits)
    visitors_by_token = visits.group(:visitor_token).size
    recurring_visitors = visitors_by_token.values.count { |v| v > 1 }
    single_time_visitors = visitors_by_token.keys.count - recurring_visitors
    {"Single time visitor": single_time_visitors, "Recurring visitors" => recurring_visitors  }
  end

  def display_percent_change(current_count, prev_count)
    return if prev_count == 0

    percent_change = percent_change(current_count, prev_count)

    raw("<div class=\"#{ percent_change > 0 ? 'positive' : 'negative' }\"><i class=\"pr-2 fa fa-caret-#{ percent_change > 0 ? 'up' : 'down' }\"></i>#{percent_change.round(2).abs} %</div>")
  end

  def tooltip_content(current_count, prev_count, interval, start_date, end_date)
    prev_interval = previous_interval(interval, start_date, end_date)
    return "There's no data from the previous #{prev_interval} to compare" if prev_count.zero?

    return "There's no change compared the previous #{prev_interval}" if current_count == prev_count

    percent_change = percent_change(current_count, prev_count)
    "This is a #{percent_change.round(2).abs} % #{percent_change > 0 ? 'increase': 'decrease'} compared to the previous #{prev_interval}"
  end

  def total_watch_time(video_view_events)
    return 0 if video_view_events.empty?
    video_view_events
    .where.not("properties ->> 'total_duration' IS NULL")
    .pluck(Arel.sql("SUM((#{Ahoy::Event.table_name}.properties ->> 'watch_time')::bigint)")).sum
  end

  def to_minutes(time_in_milisecond)
    "#{number_with_delimiter((time_in_milisecond.to_f / (1000 * 60)).round(2) , :delimiter => ',')} min"
  end

  def total_views(video_view_events)
    return 0 if video_view_events.empty?
    video_view_events
    .where.not("properties ->> 'total_duration' IS NULL")
    .pluck(Arel.sql("SUM(CASE WHEN (#{Ahoy::Event.table_name}.properties ->> 'video_start')::boolean THEN 1 ELSE 0 END)")).sum
  end

  def avg_view_duration(video_view_events)
    total_watch_time(video_view_events).to_f / (total_views(video_view_events).nonzero? || 1)
  end

  def avg_view_percentage(video_view_events)
    video_view_events
    .where.not("properties ->> 'total_duration' IS NULL")
    .pluck(Arel.sql("((properties ->> 'watch_time')::float / COALESCE((properties ->> 'total_duration')::float, 1)) * 100")).sum / (total_views(video_view_events).nonzero? || 1)
  end

  def top_three_videos(video_view_events, previous_video_view_events)
    video_view_events
      .with_api_resource
      .where.not("properties ->> 'total_duration' IS NULL")
      .group(:resource_id)
      .reorder("SUM(is_viewed) DESC", "total_watch_time DESC")
      .select(:resource_id,
        "SUM(watch_time)::INT AS total_watch_time",
        "SUM(is_viewed) AS total_views",
        "COALESCE(MAX(total_duration), 1)::float AS duration",
        "json_agg(ahoy_events.name) AS names",
        "json_agg(namespace_id) AS namespace_ids")
      .limit(3)
      .as_json
      .map(&:with_indifferent_access)
      .each do |video_event|
        previous_period_event = previous_video_view_events.jsonb_search(:properties, { resource_id: video_event[:resource_id] })
        api_resource = ApiResource.find_by(id: video_event[:resource_id])

        video_event[:name] = video_event[:names].uniq.first
        video_event[:namespace_id] = video_event[:namespace_ids].uniq.first
        video_event[:previous_period_total_views] = total_views(previous_period_event)
        video_event[:previous_period_total_watch_time] = total_watch_time(previous_period_event)
        video_event[:resource_title] = api_resource&.properties.dig(api_resource&.api_namespace.analytics_metadata&.dig("title")) || "Resource Id: #{video_event[:resource_id]}"
        video_event[:resource_author] = api_resource&.properties.dig(api_resource&.api_namespace.analytics_metadata&.dig("author"))
        video_event[:resource_image] = api_resource&.non_primitive_properties.find_by(field_type: "file", label: api_resource&.api_namespace.analytics_metadata&.dig("thumbnail"))&.file_url

        video_event.delete(:names)
        video_event.delete(:namespace_ids)
        video_event.delete(:id)
      end
  end

  private
  def split_into(start_date, end_date)
    time_in_days = (end_date - start_date).to_i

    if time_in_days <= 1
      [:hour_of_day, '%I %P']
    elsif time_in_days <= 7
      [:day, '%-d %^b %Y']
    elsif time_in_days <= 30
      [:week, '%V']
    elsif time_in_days <= 365
      [:month, '%^b %Y']
    else
      [:year, '%Y']
    end
  end

  def previous_interval(interval, start_date, end_date)
    today = Date.current
    interval = interval || today.strftime('%B %Y')

    case interval
    when "3 months", "6 months", "1 year"
      interval
    when "#{today.strftime('%B %Y')}"
      "month"
    else
      "#{ (end_date - start_date).to_i } days"
    end
  end

  def percent_change(current_count, prev_count)
    ((current_count - prev_count).to_f / prev_count) * 100
  end
end