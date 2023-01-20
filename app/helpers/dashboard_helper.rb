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
    page_visit_events.where.not('ahoy_visits.device_type': nil).group_by { |u| u.visit.device_type }.map do |key, value|
      { name: key, data: Ahoy::Event.where(id: value.pluck(:id)).group_by_period(period, :time, range: start_date..end_date, format: format).count }
    end
  end


  def visitors_chart_data(visits)
    visitors_by_token = visits.group(:visitor_token).count
    recurring_visitors = visitors_by_token.values.count { |v| v > 1 }
    single_time_visitors = visitors_by_token.keys.count - recurring_visitors
    {"Single time visitor": single_time_visitors, "Recurring visitors" => recurring_visitors  }
  end

  def display_percent_change(current_count, prev_count)
    return if prev_count == 0

    percent_change = (((current_count - prev_count).to_f / prev_count) * 100).round(2).abs

    raw("<div class=\"#{ percent_change < 0 ? 'positive' : 'negative' }\"><i class=\"pr-2 fa fa-caret-#{ percent_change < 0 ? 'up' : 'down' }\"></i>#{percent_change} %</div>")
  end

  def total_watch_time(video_watch_events)
    video_watch_events.sum { |event| event.properties['watch_time'].to_i }
  end

  def to_minutes(time_in_milisecond)
    "#{number_with_delimiter((time_in_milisecond.to_f / (1000 * 60)).round(2) , :delimiter => ',')} min"
  end

  def total_views(video_watch_events)
    video_watch_events.select { |event| event.properties['video_start'] }.size
  end

  def avg_view_duration(video_watch_events)
    total_watch_time(video_watch_events).to_f / (total_views(video_watch_events).nonzero? || 1)
  end

  def avg_view_percentage(video_watch_events)
    view_percentage_arr = video_watch_events.group_by { |event| event.properties['resource_id'] }.map do |_resource_id, events|
      (events.sum { |event| event.properties['watch_time'].to_f  / event.properties['total_duration'].to_f }) * 100
    end
    view_percentage_arr.sum / (video_watch_events.size.nonzero? || 1)
  end

  def top_three_videos(video_watch_events, previous_video_watch_events) 
    video_watch_events.group_by { |event| event.properties['resource_id'] }.map do |resource_id, events|
      previous_period_event = previous_video_watch_events.jsonb_search(:properties, { resource_id: resource_id })
      api_resource = ApiResource.find_by(id: resource_id) 
      { 
        total_views: total_views(events),
        total_watch_time:  total_watch_time(events),
        previous_period_total_views: total_views(previous_period_event),
        previous_period_total_watch_time: total_watch_time(previous_period_event),
        resource_title: api_resource.properties.dig(api_resource.api_namespace.social_share_metadata.dig("title")),
        resource_image: api_resource.non_primitive_properties.find_by(field_type: "file", label: api_resource.api_namespace.social_share_metadata.dig("image"))&.file_url,
        duration: events.first.properties['total_duration']
      }
    end.sort_by {|event| event[:total_views]}.reverse.first(3)
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
end