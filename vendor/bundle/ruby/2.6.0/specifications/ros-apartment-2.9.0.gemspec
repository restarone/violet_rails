# -*- encoding: utf-8 -*-
# stub: ros-apartment 2.9.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ros-apartment".freeze
  s.version = "2.9.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ryan Brunner".freeze, "Brad Robertson".freeze, "Rui Baltazar".freeze]
  s.date = "2021-01-21"
  s.description = "Apartment allows Rack applications to deal with database multitenancy through ActiveRecord".freeze
  s.email = ["ryan@influitive.com".freeze, "brad@influitive.com".freeze, "rui.p.baltazar@gmail.com".freeze]
  s.homepage = "https://github.com/rails-on-services/apartment".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3.1".freeze
  s.summary = "A Ruby gem for managing database multitenancy. Apartment Gem drop in replacement".freeze

  s.installed_by_version = "3.0.3.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activerecord>.freeze, [">= 5.0.0", "< 6.2"])
      s.add_runtime_dependency(%q<parallel>.freeze, ["< 2.0"])
      s.add_runtime_dependency(%q<public_suffix>.freeze, [">= 2.0.5", "< 5.0"])
      s.add_runtime_dependency(%q<rack>.freeze, [">= 1.3.6", "< 3.0"])
      s.add_development_dependency(%q<appraisal>.freeze, ["~> 2.2"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 1.3", "< 3.0"])
      s.add_development_dependency(%q<capybara>.freeze, ["~> 2.0"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.4"])
      s.add_development_dependency(%q<rspec-rails>.freeze, ["~> 3.4"])
      s.add_development_dependency(%q<mysql2>.freeze, ["~> 0.5"])
      s.add_development_dependency(%q<pg>.freeze, ["~> 1.2"])
      s.add_development_dependency(%q<sqlite3>.freeze, ["~> 1.3.6"])
    else
      s.add_dependency(%q<activerecord>.freeze, [">= 5.0.0", "< 6.2"])
      s.add_dependency(%q<parallel>.freeze, ["< 2.0"])
      s.add_dependency(%q<public_suffix>.freeze, [">= 2.0.5", "< 5.0"])
      s.add_dependency(%q<rack>.freeze, [">= 1.3.6", "< 3.0"])
      s.add_dependency(%q<appraisal>.freeze, ["~> 2.2"])
      s.add_dependency(%q<bundler>.freeze, [">= 1.3", "< 3.0"])
      s.add_dependency(%q<capybara>.freeze, ["~> 2.0"])
      s.add_dependency(%q<rake>.freeze, ["~> 13.0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.4"])
      s.add_dependency(%q<rspec-rails>.freeze, ["~> 3.4"])
      s.add_dependency(%q<mysql2>.freeze, ["~> 0.5"])
      s.add_dependency(%q<pg>.freeze, ["~> 1.2"])
      s.add_dependency(%q<sqlite3>.freeze, ["~> 1.3.6"])
    end
  else
    s.add_dependency(%q<activerecord>.freeze, [">= 5.0.0", "< 6.2"])
    s.add_dependency(%q<parallel>.freeze, ["< 2.0"])
    s.add_dependency(%q<public_suffix>.freeze, [">= 2.0.5", "< 5.0"])
    s.add_dependency(%q<rack>.freeze, [">= 1.3.6", "< 3.0"])
    s.add_dependency(%q<appraisal>.freeze, ["~> 2.2"])
    s.add_dependency(%q<bundler>.freeze, [">= 1.3", "< 3.0"])
    s.add_dependency(%q<capybara>.freeze, ["~> 2.0"])
    s.add_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.4"])
    s.add_dependency(%q<rspec-rails>.freeze, ["~> 3.4"])
    s.add_dependency(%q<mysql2>.freeze, ["~> 0.5"])
    s.add_dependency(%q<pg>.freeze, ["~> 1.2"])
    s.add_dependency(%q<sqlite3>.freeze, ["~> 1.3.6"])
  end
end
