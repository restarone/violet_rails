# -*- encoding: utf-8 -*-
# stub: turnout 2.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "turnout".freeze
  s.version = "2.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Adam Crownoble".freeze]
  s.date = "2018-12-04"
  s.description = "Turnout makes it easy to put your Rails application into maintenance mode".freeze
  s.email = "adam@codenoble.com".freeze
  s.homepage = "https://github.com/biola/turnout".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3.1".freeze
  s.summary = "A Rack based maintenance mode plugin for Rails".freeze

  s.installed_by_version = "3.0.3.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<tilt>.freeze, [">= 1.4", "< 3"])
      s.add_runtime_dependency(%q<rack>.freeze, [">= 1.3", "< 3"])
      s.add_runtime_dependency(%q<rack-accept>.freeze, ["~> 0.4"])
      s.add_runtime_dependency(%q<i18n>.freeze, [">= 0.7", "< 2"])
      s.add_development_dependency(%q<rack-test>.freeze, ["~> 0.6"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
      s.add_development_dependency(%q<rspec-its>.freeze, ["~> 1.0"])
      s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.10", ">= 0.10"])
      s.add_development_dependency(%q<simplecov-summary>.freeze, ["~> 0.0.4", ">= 0.0.4"])
    else
      s.add_dependency(%q<tilt>.freeze, [">= 1.4", "< 3"])
      s.add_dependency(%q<rack>.freeze, [">= 1.3", "< 3"])
      s.add_dependency(%q<rack-accept>.freeze, ["~> 0.4"])
      s.add_dependency(%q<i18n>.freeze, [">= 0.7", "< 2"])
      s.add_dependency(%q<rack-test>.freeze, ["~> 0.6"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
      s.add_dependency(%q<rspec-its>.freeze, ["~> 1.0"])
      s.add_dependency(%q<simplecov>.freeze, ["~> 0.10", ">= 0.10"])
      s.add_dependency(%q<simplecov-summary>.freeze, ["~> 0.0.4", ">= 0.0.4"])
    end
  else
    s.add_dependency(%q<tilt>.freeze, [">= 1.4", "< 3"])
    s.add_dependency(%q<rack>.freeze, [">= 1.3", "< 3"])
    s.add_dependency(%q<rack-accept>.freeze, ["~> 0.4"])
    s.add_dependency(%q<i18n>.freeze, [">= 0.7", "< 2"])
    s.add_dependency(%q<rack-test>.freeze, ["~> 0.6"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_dependency(%q<rspec-its>.freeze, ["~> 1.0"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.10", ">= 0.10"])
    s.add_dependency(%q<simplecov-summary>.freeze, ["~> 0.0.4", ">= 0.0.4"])
  end
end
