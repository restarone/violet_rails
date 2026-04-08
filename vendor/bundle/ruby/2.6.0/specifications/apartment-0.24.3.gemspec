# -*- encoding: utf-8 -*-
# stub: apartment 0.24.3 ruby lib

Gem::Specification.new do |s|
  s.name = "apartment".freeze
  s.version = "0.24.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ryan Brunner".freeze, "Brad Robertson".freeze]
  s.date = "2014-03-05"
  s.description = "Apartment allows Rack applications to deal with database multitenancy through ActiveRecord".freeze
  s.email = ["ryan@influitive.com".freeze, "brad@influitive.com".freeze]
  s.homepage = "https://github.com/influitive/apartment".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3.1".freeze
  s.summary = "A Ruby gem for managing database multitenancy".freeze

  s.installed_by_version = "3.0.3.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activerecord>.freeze, [">= 3.1.2"])
      s.add_runtime_dependency(%q<rack>.freeze, [">= 1.3.6"])
      s.add_development_dependency(%q<appraisal>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 0.9"])
      s.add_development_dependency(%q<rspec-rails>.freeze, ["~> 2.14"])
      s.add_development_dependency(%q<guard-rspec>.freeze, ["~> 4.2"])
      s.add_development_dependency(%q<capybara>.freeze, ["~> 1.0.0"])
      s.add_development_dependency(%q<mysql2>.freeze, ["~> 0.3.10"])
      s.add_development_dependency(%q<pg>.freeze, [">= 0.11.0"])
      s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
    else
      s.add_dependency(%q<activerecord>.freeze, [">= 3.1.2"])
      s.add_dependency(%q<rack>.freeze, [">= 1.3.6"])
      s.add_dependency(%q<appraisal>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, ["~> 0.9"])
      s.add_dependency(%q<rspec-rails>.freeze, ["~> 2.14"])
      s.add_dependency(%q<guard-rspec>.freeze, ["~> 4.2"])
      s.add_dependency(%q<capybara>.freeze, ["~> 1.0.0"])
      s.add_dependency(%q<mysql2>.freeze, ["~> 0.3.10"])
      s.add_dependency(%q<pg>.freeze, [">= 0.11.0"])
      s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<activerecord>.freeze, [">= 3.1.2"])
    s.add_dependency(%q<rack>.freeze, [">= 1.3.6"])
    s.add_dependency(%q<appraisal>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, ["~> 0.9"])
    s.add_dependency(%q<rspec-rails>.freeze, ["~> 2.14"])
    s.add_dependency(%q<guard-rspec>.freeze, ["~> 4.2"])
    s.add_dependency(%q<capybara>.freeze, ["~> 1.0.0"])
    s.add_dependency(%q<mysql2>.freeze, ["~> 0.3.10"])
    s.add_dependency(%q<pg>.freeze, [">= 0.11.0"])
    s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
  end
end
