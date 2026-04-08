# -*- encoding: utf-8 -*-
# stub: friendly_id 5.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "friendly_id".freeze
  s.version = "5.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Norman Clarke".freeze, "Philip Arndt".freeze]
  s.date = "1980-01-02"
  s.description = "FriendlyId is the \"Swiss Army bulldozer\" of slugging and permalink plugins for Active Record. It lets you create pretty URLs and work with human-friendly strings as if they were numeric ids.".freeze
  s.email = ["norman@njclarke.com".freeze, "gems@p.arndt.io".freeze]
  s.homepage = "https://github.com/norman/friendly_id".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.1.0".freeze)
  s.rubygems_version = "3.4.1".freeze
  s.summary = "A comprehensive slugging and pretty-URL plugin.".freeze

  s.installed_by_version = "3.4.1" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 4.0.0"])
  s.add_development_dependency(%q<coveralls>.freeze, [">= 0"])
  s.add_development_dependency(%q<railties>.freeze, [">= 4.0"])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.3"])
  s.add_development_dependency(%q<mocha>.freeze, ["~> 2.1"])
  s.add_development_dependency(%q<yard>.freeze, [">= 0"])
  s.add_development_dependency(%q<i18n>.freeze, [">= 0"])
  s.add_development_dependency(%q<ffaker>.freeze, [">= 0"])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
end
