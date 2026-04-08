module EmberCli
  module Assets
    class DirectoryAssetMap
      def initialize(directory)
        @directory = Pathname.new(directory)
      end

      def to_h
        {
          "assets" => files_with_data,
          "prepend" => "assets/",
        }
      end

      private

      attr_reader :directory

      def files_with_data
        files.reduce({}) do |manifest, file|
          name = File.basename(file.path)

          manifest[name] = name

          manifest
        end
      end


      def files
        directory.children.map { |path| File.new(path) }
      end
    end
  end
end
