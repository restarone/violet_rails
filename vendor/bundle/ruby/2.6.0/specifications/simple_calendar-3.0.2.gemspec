# -*- encoding: utf-8 -*-
# stub: simple_calendar 3.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "simple_calendar".freeze
  s.version = "3.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Chris Oliver".freeze]
  s.date = "2023-08-25"
  s.description = "A simple Rails calendar".freeze
  s.email = ["excid3@gmail.com".freeze]
  s.homepage = "https://github.com/excid3/simple_calendar".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3.1".freeze
  s.summary = "A simple Rails calendar".freeze

  s.installed_by_version = "3.0.3.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rails>.freeze, [">= 6.1"])
    else
      s.add_dependency(%q<rails>.freeze, [">= 6.1"])
    end
  else
    s.add_dependency(%q<rails>.freeze, [">= 6.1"])
  end
end
