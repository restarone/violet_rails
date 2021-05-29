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
end
