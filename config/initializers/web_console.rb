Rails.application.reloader.to_prepare do
  module WebConsole
    class Permissions
      # monkey patch for dynamically allowing web console rendering
      def include?(network)
        return Subdomain.current.web_console_enabled?
      end
    end
  end
end
