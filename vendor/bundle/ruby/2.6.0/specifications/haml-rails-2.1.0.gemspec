# -*- encoding: utf-8 -*-
# stub: haml-rails 2.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "haml-rails".freeze
  s.version = "2.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 2.0.0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andr\u00E9 Arko".freeze]
  s.date = "2022-09-24"
  s.description = "Haml-rails provides Haml generators for Rails 5. It also enables Haml as the templating engine for you, so you don't have to screw around in your own application.rb when your Gemfile already clearly indicated what templating engine you have installed. Hurrah.".freeze
  s.email = ["andre@arko.net".freeze]
  s.homepage = "https://github.com/haml/haml-rails".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.0.3.1".freeze
  s.summary = "let your Gemfile do the configuring".freeze

  s.installed_by_version = "3.0.3.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<haml>.freeze, [">= 4.0.6"])
      s.add_runtime_dependency(%q<activesupport>.freeze, [">= 5.1"])
      s.add_runtime_dependency(%q<actionpack>.freeze, [">= 5.1"])
      s.add_runtime_dependency(%q<railties>.freeze, [">= 5.1"])
      s.add_development_dependency(%q<html2haml>.freeze, [">= 1.0.1"])
      s.add_development_dependency(%q<rails>.freeze, [">= 5.1"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<appraisal>.freeze, [">= 0"])
    else
      s.add_dependency(%q<haml>.freeze, [">= 4.0.6"])
      s.add_dependency(%q<activesupport>.freeze, [">= 5.1"])
      s.add_dependency(%q<actionpack>.freeze, [">= 5.1"])
      s.add_dependency(%q<railties>.freeze, [">= 5.1"])
      s.add_dependency(%q<html2haml>.freeze, [">= 1.0.1"])
      s.add_dependency(%q<rails>.freeze, [">= 5.1"])
      s.add_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<appraisal>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<haml>.freeze, [">= 4.0.6"])
    s.add_dependency(%q<activesupport>.freeze, [">= 5.1"])
    s.add_dependency(%q<actionpack>.freeze, [">= 5.1"])
    s.add_dependency(%q<railties>.freeze, [">= 5.1"])
    s.add_dependency(%q<html2haml>.freeze, [">= 1.0.1"])
    s.add_dependency(%q<rails>.freeze, [">= 5.1"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<appraisal>.freeze, [">= 0"])
  end
end
