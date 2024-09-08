if RUBY_VERSION != '3.0.0'

  if NextRails.next?
    # Do things "the Rails 7 way"
    p "NO EMBER SUPPORT IN VIOLET RAILS 7"
  else
    # Do things "the Rails 6 way"
    EmberCli.configure do |c|
      c.app :client
    end
  end
end
