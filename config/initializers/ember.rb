if RUBY_VERSION != '3.0.0' && ENV['EMBER_ENABLED']
  Rails.application.reloader.to_prepare do
    EmberCli.configure do |c|
      c.app :client
    end
  end
end
