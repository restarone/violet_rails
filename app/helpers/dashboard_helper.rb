module DashboardHelper
  def redact_private_urls(url)
    return if !url
    exclusions = Subdomain::PRIVATE_URL_PATHS
    if exclusions.any? {|exclusion| url.include?(exclusion) }
      "private-system-url-redacted"
    else
      url
    end
  end
end
