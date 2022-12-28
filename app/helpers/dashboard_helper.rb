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
