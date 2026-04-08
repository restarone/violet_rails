# -*- encoding: utf-8 -*-
# stub: webdrivers 5.3.1 ruby lib

Gem::Specification.new do |s|
  s.name = "webdrivers".freeze
  s.version = "5.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/titusfortner/webdrivers/issues", "changelog_uri" => "https://github.com/titusfortner/webdrivers/blob/master/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/gems/webdrivers/5.3.1", "source_code_uri" => "https://github.com/titusfortner/webdrivers/tree/v5.3.1" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Titus Fortner".freeze, "Lakshya Kapoor".freeze, "Thomas Walpole".freeze]
  s.date = "2023-07-31"
  s.description = "Run Selenium tests more easily with install and updates for all supported webdrivers.".freeze
  s.email = ["titusfortner@gmail.com".freeze, "kapoorlakshya@gmail.com".freeze]
  s.homepage = "https://github.com/titusfortner/webdrivers".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "Webdrivers gem update options\n*****************************\n\nSelenium itself now manages drivers by default: https://www.selenium.dev/documentation/selenium_manager\n* If you are using Ruby 3+ \u2014 please update to Selenium 4.11+ and stop requiring this gem\n* If you are using Ruby 2.6+ and Selenium 4.0+ \u2014 this version will work for now\n* If you use Ruby < 2.6 or Selenium 3, a 6.0 version of this gem with additional support is planned\n\nRestrict your gemfile to \"webdrivers\", \"= 5.3.0\" to stop seeing this message\n".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 2.6.0".freeze)
  s.rubygems_version = "3.4.1".freeze
  s.summary = "Easy download and use of browser drivers.".freeze

  s.installed_by_version = "3.4.1" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<ffi>.freeze, ["~> 1.0"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 12.0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.89"])
  s.add_development_dependency(%q<rubocop-packaging>.freeze, ["~> 0.5.0"])
  s.add_development_dependency(%q<rubocop-performance>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, ["~> 1.42"])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.16"])
  s.add_runtime_dependency(%q<nokogiri>.freeze, ["~> 1.6"])
  s.add_runtime_dependency(%q<rubyzip>.freeze, [">= 1.3.0"])
  s.add_runtime_dependency(%q<selenium-webdriver>.freeze, ["~> 4.0", "< 4.11"])
end
