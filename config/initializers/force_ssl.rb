# handles protocol everywhere that uses url_helpers
Rails.application.routes.default_url_options[:protocol] = (Rails.env.production? || Rails.env.staging?) ? 'https': 'http'