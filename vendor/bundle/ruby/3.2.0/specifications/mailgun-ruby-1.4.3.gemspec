# -*- encoding: utf-8 -*-
# stub: mailgun-ruby 1.4.3 ruby lib

Gem::Specification.new do |s|
  s.name = "mailgun-ruby".freeze
  s.version = "1.4.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "documentation_uri" => "https://documentation.mailgun.com/", "source_code_uri" => "https://github.com/mailgun/mailgun-ruby" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mailgun".freeze, "Travis Swientek".freeze]
  s.date = "1980-01-02"
  s.description = "Mailgun's Official Ruby SDK for interacting with the Mailgun API.".freeze
  s.email = "support@mailgunhq.com".freeze
  s.homepage = "https://www.mailgun.com/".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0.0".freeze)
  s.rubygems_version = "3.4.1".freeze
  s.summary = "Mailgun's Official Ruby SDK".freeze

  s.installed_by_version = "3.4.1" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 1.16.2"])
  s.add_development_dependency(%q<pry>.freeze, ["~> 0.16.0"])
  s.add_development_dependency(%q<rails>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.3.1"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.13.0"])
  s.add_development_dependency(%q<rspec-its>.freeze, ["~> 2.0.0"])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
  s.add_development_dependency(%q<simplecov-json>.freeze, [">= 0"])
  s.add_development_dependency(%q<vcr>.freeze, ["~> 6.4.0"])
  s.add_development_dependency(%q<webmock>.freeze, ["~> 3.7"])
  s.add_runtime_dependency(%q<faraday>.freeze, ["~> 2.1"])
  s.add_runtime_dependency(%q<faraday-multipart>.freeze, ["< 2"])
  s.add_runtime_dependency(%q<mini_mime>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<zeitwerk>.freeze, [">= 0"])
end
