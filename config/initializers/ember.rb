if RUBY_VERSION != '3.1.0'
  EmberCli.configure do |c|
    c.app :client
  end
end
