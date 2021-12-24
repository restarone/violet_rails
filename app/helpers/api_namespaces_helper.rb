module ApiNamespacesHelper
  def api_base_url(subdomain, namespace)
    "#{subdomain.hostname}/api/#{namespace.version}/#{namespace.name}"
  end

  def system_paths
    Comfy::Cms::Page.all.pluck(:full_path)
  end
end
