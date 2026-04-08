module EmberCli
  module Assets
    class Paths
      def initialize(app)
        @app = app
      end

      def assets
        app.dist_path.join("assets")
      end

      def asset_map
        Pathname.glob(assets.join("assetMap*.json")).first
      end

      def package_json
        app.root_path.join("package.json")
      end

      protected

      attr_reader :app
    end
  end
end
