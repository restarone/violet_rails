require "ember_cli/assets/paths"
require "ember_cli/assets/asset_map"
require "ember_cli/assets/directory_asset_map"

module EmberCli
  module Assets
    class Lookup
      def initialize(app)
        @paths = Paths.new(app)
      end

      def javascript_assets
        asset_map.javascripts
      end

      def stylesheet_assets
        asset_map.stylesheets
      end

      private

      attr_reader :paths

      def asset_map
        AssetMap.new(
          name: name_from_package_json,
          asset_map: asset_map_hash.to_h,
        )
      end

      def asset_map_file
        paths.asset_map
      end

      def asset_map_hash
        if asset_map_file.present? && asset_map_file.exist?
          JSON.parse(asset_map_file.read)
        else
          DirectoryAssetMap.new(paths.assets)
        end
      end

      def name_from_package_json
        package_json.fetch("name")
      end

      def package_json
        @package_json ||= JSON.parse(paths.package_json.read)
      end
    end
  end
end
