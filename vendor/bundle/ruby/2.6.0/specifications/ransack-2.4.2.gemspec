# -*- encoding: utf-8 -*-
# stub: ransack 2.4.2 ruby lib

Gem::Specification.new do |s|
  s.name = "ransack".freeze
  s.version = "2.4.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ernie Miller".freeze, "Ryan Bigg".freeze, "Jon Atack".freeze, "Sean Carroll".freeze]
  s.date = "2021-01-23"
  s.description = "Ransack is the successor to the MetaSearch gem. It improves and expands upon MetaSearch's functionality, but does not have a 100%-compatible API.".freeze
  s.email = ["ernie@erniemiller.org".freeze, "radarlistener@gmail.com".freeze, "jonnyatack@gmail.com".freeze, "sfcarroll@gmail.com".freeze]
  s.homepage = "https://github.com/activerecord-hackery/ransack".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.0.3.1".freeze
  s.summary = "Object-based searching for Active Record and Mongoid (currently).".freeze

  s.installed_by_version = "3.0.3.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activerecord>.freeze, [">= 5.2.4"])
      s.add_runtime_dependency(%q<activesupport>.freeze, [">= 5.2.4"])
      s.add_runtime_dependency(%q<i18n>.freeze, [">= 0"])
    else
      s.add_dependency(%q<activerecord>.freeze, [">= 5.2.4"])
      s.add_dependency(%q<activesupport>.freeze, [">= 5.2.4"])
      s.add_dependency(%q<i18n>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<activerecord>.freeze, [">= 5.2.4"])
    s.add_dependency(%q<activesupport>.freeze, [">= 5.2.4"])
    s.add_dependency(%q<i18n>.freeze, [">= 0"])
  end
end
