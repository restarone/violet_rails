# -*- encoding: utf-8 -*-
# stub: local_time 3.0.3 ruby lib

Gem::Specification.new do |s|
  s.name = "local_time".freeze
  s.version = "3.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Javan Makhmali".freeze, "Sam Stephenson".freeze]
  s.date = "2025-03-13"
  s.email = "javan@basecamp.com".freeze
  s.homepage = "https://github.com/basecamp/local_time".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.1".freeze
  s.summary = "Rails engine for cache-friendly, client-side local time".freeze

  s.installed_by_version = "3.4.1" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
  s.add_development_dependency(%q<rails>.freeze, ["~> 7.0"])
  s.add_development_dependency(%q<rails-dom-testing>.freeze, ["~> 2.0"])
end
