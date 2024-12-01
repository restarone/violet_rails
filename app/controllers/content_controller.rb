class ContentController < ApplicationController
  before_action :track_ahoy_visit, :process_subdomain_smart_link_redirect, raise: false

  private

  def process_subdomain_smart_link_redirect
    subdomain = request.subdomain
    url_parameters = request.path
    if !subdomain.blank?
      unless Subdomain.all.pluck(:name).any?{|name| subdomain == name}
        # process S2 link - append parameters for 2nd redirect
        return redirect_to "#{root_url(subdomain: Subdomain.current.name)}?s2_redirect_to=#{subdomain}&s2_query=#{subdomain}&s2_url_params=#{url_parameters}&s2_subdomain=#{subdomain}"
      end
    end
  end
end
