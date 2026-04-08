# -*- encoding: utf-8 -*-
# stub: puppeteer-ruby 0.45.6 ruby lib

Gem::Specification.new do |s|
  s.name = "puppeteer-ruby".freeze
  s.version = "0.45.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["YusukeIwaki".freeze]
  s.bindir = "exe".freeze
  s.date = "2024-09-14"
  s.email = ["q7w8e9w8q7w8e9@yahoo.co.jp".freeze]
  s.homepage = "https://github.com/YusukeIwaki/puppeteer-ruby".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.4.1".freeze
  s.summary = "A ruby port of puppeteer".freeze

  s.installed_by_version = "3.4.1" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<concurrent-ruby>.freeze, [">= 1.1", "< 1.4"])
  s.add_runtime_dependency(%q<websocket-driver>.freeze, [">= 0.6.0"])
  s.add_runtime_dependency(%q<mime-types>.freeze, [">= 3.0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<chunky_png>.freeze, [">= 0"])
  s.add_development_dependency(%q<dry-inflector>.freeze, [">= 0"])
  s.add_development_dependency(%q<pry-byebug>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.1.0"])
  s.add_development_dependency(%q<rollbar>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.12.0"])
  s.add_development_dependency(%q<rspec_junit_formatter>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.50.0"])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<sinatra>.freeze, ["< 4.0.0"])
  s.add_development_dependency(%q<webrick>.freeze, [">= 0"])
  s.add_development_dependency(%q<yard>.freeze, [">= 0"])
end
