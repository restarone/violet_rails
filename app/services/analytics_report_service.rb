class AnalyticsReportService
  def initialize(subdomain)
    @subdomain = subdomain
    @report_frequency = @subdomain.analytics_report_frequency
  end

  def call
    send_analytics_report
  end

  private

  attr_reader :report_frequency

  def send_analytics_report
    # return unless (@subdomain.analytics_report_frequency != Subdomain::REPORT_FREQUENCY_MAPPING[:never]) && (@subdomain.analytics_report_last_sent.nil? || @subdomain.analytics_report_last_sent < eval(@subdomain.analytics_report_frequency).ago)
    ctas = CallToAction.joins(:call_to_action_responses).where("call_to_action_responses.created_at > ?", eval("#{report_frequency}.ago"))
    visits = Subdomain.current.ahoy_visits.unscoped.where("started_at >= ?", eval("#{report_frequency}.ago"))
    @subdomain.update(analytics_report_last_sent: Time.zone.now)
    UserMailer.analytics_report(ctas, visits).deliver_now
  end
end
