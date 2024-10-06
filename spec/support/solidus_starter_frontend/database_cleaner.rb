RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.before :suite do
    DatabaseCleaner.clean_with :truncation
  end

  # Around each spec check if it is a Javascript test and switch between using
  # database transactions or not where necessary.
  config.around(:each) do |example|
    DatabaseCleaner.strategy = RSpec.current_example.metadata[:js] ? :truncation : :transaction
    DatabaseCleaner.cleaning { example.run }
  end
end
