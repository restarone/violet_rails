module ApiNamespacesHelper
  def api_base_url(subdomain, namespace)
    "#{subdomain.hostname}/api/#{namespace.version}/#{namespace.name}"
  end

  def graphql_base_url(subdomain, namespace)
    "#{subdomain.hostname}/graphql"
  end

  def system_paths
    Comfy::Cms::Page.all.pluck(:full_path)
  end
end
