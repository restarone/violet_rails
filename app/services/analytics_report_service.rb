class AnalyticsReportService
  def initialize(subdomain)
    @subdomain = subdomain
    @report_frequency = @subdomain.analytics_report_frequency
  end

  def call
    analytics_report_json
  end

  private

  attr_reader :report_frequency

  def analytics_report_json
    { ctas: cta_json,
      visits: visits_json,
      users: users_json
    }
  end

  def cta_json
    ctas = []
    CallToAction.all.each do |cta|
      ctas << {
        title: cta.title,
        id: cta.id,
        response_count: cta.call_to_action_responses.where('created_at > ?', eval("#{report_frequency}.ago")).count
      }
    end

    ctas
  end

  def visits_json
    response = {}
    visits = @subdomain.ahoy_visits.unscoped.where('started_at >= ?', eval("#{report_frequency}.ago"))
    visited_by = %i[country region city referring_domain landing_page]

    visited_by.each do |each_elm|
      response[each_elm] = visits.group(each_elm).count
    end
    response
  end

  def users_json
    User.where('created_at >= ?', eval("#{report_frequency}.ago")).as_json(only: User.public_attributes)
  end
end
