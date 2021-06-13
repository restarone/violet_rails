module ApiNamespacesHelper
  def api_base_url(subdomain, namespace)
    "#{subdomain.hostname}/api/#{namespace.version}/#{namespace.name}"
  end
end
