# -*- encoding: utf-8 -*-
# stub: ember-cli-rails 0.10.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ember-cli-rails".freeze
  s.version = "0.10.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Pavel Pravosud".freeze, "Jonathan Jackson".freeze, "Sean Doyle".freeze]
  s.date = "2017-09-01"
  s.email = ["pavel@pravosud.com".freeze, "jonathan.jackson1@me.com".freeze, "sean.p.doyle24@gmail.com".freeze]
  s.homepage = "https://github.com/thoughtbot/ember-cli-rails".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2.0".freeze)
  s.rubygems_version = "3.4.1".freeze
  s.summary = "Integration between Ember CLI and Rails".freeze

  s.installed_by_version = "3.4.1" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<ember-cli-rails-assets>.freeze, ["~> 0.6.2"])
  s.add_runtime_dependency(%q<railties>.freeze, [">= 3.2"])
  s.add_runtime_dependency(%q<cocaine>.freeze, ["~> 0.5.8"])
  s.add_runtime_dependency(%q<html_page>.freeze, ["~> 0.1.0"])
  s.add_development_dependency(%q<generator_spec>.freeze, ["~> 0.9.0"])
end
