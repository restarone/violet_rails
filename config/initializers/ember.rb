if RUBY_VERSION != '3.0.0'
  EmberCli.configure do |c|
    c.app :client
  end
end
