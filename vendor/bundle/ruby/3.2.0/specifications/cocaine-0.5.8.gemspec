# -*- encoding: utf-8 -*-
# stub: cocaine 0.5.8 ruby lib

Gem::Specification.new do |s|
  s.name = "cocaine".freeze
  s.version = "0.5.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jon Yurek".freeze]
  s.date = "2015-11-20"
  s.description = "A small library for doing (command) lines".freeze
  s.email = "jyurek@thoughtbot.com".freeze
  s.homepage = "https://github.com/thoughtbot/cocaine".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.1".freeze
  s.summary = "A small library for doing (command) lines".freeze

  s.installed_by_version = "3.4.1" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<climate_control>.freeze, [">= 0.0.3", "< 1.0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<bourne>.freeze, [">= 0"])
  s.add_development_dependency(%q<mocha>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<activesupport>.freeze, [">= 3.0.0", "< 5.0"])
  s.add_development_dependency(%q<pry>.freeze, [">= 0"])
end
