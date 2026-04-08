require "ember_cli/assets/lookup"

module EmberCliRailsAssetsHelper
  def include_ember_script_tags(name, prepend: "")
    EmberCli[name].build

    assets = EmberCli::Assets::Lookup.new(EmberCli[name])

    assets.javascript_assets.
      map { |src| [prepend, src].join }.
      map { |src| %{<script src="#{src}"></script>}.html_safe }.
      inject(&:+)
  end

  def include_ember_stylesheet_tags(name, prepend: "")
    EmberCli[name].build

    assets = EmberCli::Assets::Lookup.new(EmberCli[name])

    assets.stylesheet_assets.
      map { |src| [prepend, src].join }.
      map { |src| %{<link rel="stylesheet" href="#{src}">}.html_safe }.
      inject(&:+)
  end
end
