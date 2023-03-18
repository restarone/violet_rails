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
    
  def page_name(page_id)
    return 'Website' if page_id.blank?

    Comfy::Cms::Page.find_by(id: page_id)&.label
  end

  def display_percent_change(current_count, prev_count)
    return if prev_count.to_i == 0

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

  def to_minutes(time_in_milisecond)
    "#{number_with_delimiter((time_in_milisecond.to_f / (1000 * 60)).round(2) , :delimiter => ',')} min"
  end

  def top_three_videos_details(current_top_videos_details, previous_top_videos_details)
    current_top_videos_details.each do |video_detail|
      video_detail.merge(previous_top_videos_details.find { |previous_video_detail| previous_video_detail[:resource_id] == video_detail[:resource_id] } || {})
    end
  end

  def event_title(event_category)
    case event_category
    when Ahoy::Event::EVENT_CATEGORIES[:click]
      'Clicks'
    when Ahoy::Event::EVENT_CATEGORIES[:form_submit]
      'Form Submissions'
    when Ahoy::Event::EVENT_CATEGORIES[:section_view]
      'Section Views'
    when 'system_events'
      'Events'
    end
  end

  def event_types(event_category)
    case event_category
    when Ahoy::Event::EVENT_CATEGORIES[:click]
      'clickables'
    when Ahoy::Event::EVENT_CATEGORIES[:form_submit]
      'submitables'
    when Ahoy::Event::EVENT_CATEGORIES[:section_view]
      'viewables'
    when 'system_events'
      'events'
    end
  end

  def split_into(start_date, end_date)
    time_in_days = (end_date - start_date).to_i

    if time_in_days <= 1
      {period: :hour_of_day, format: '%I %P'}
    elsif time_in_days <= 7
      {period: :day, format: '%-d %^b %Y'}
    elsif time_in_days <= 30
      {period: :week, format: '%V'}
    elsif time_in_days <= 365
      {period: :month, format: '%^b %Y'}
    else
      {period: :year, format: '%Y'}
    end
  end

  private
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