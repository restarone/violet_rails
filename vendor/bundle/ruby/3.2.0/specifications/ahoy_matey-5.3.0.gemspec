# -*- encoding: utf-8 -*-
# stub: ahoy_matey 5.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ahoy_matey".freeze
  s.version = "5.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andrew Kane".freeze]
  s.date = "2025-02-01"
  s.email = "andrew@ankane.org".freeze
  s.homepage = "https://github.com/ankane/ahoy".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1".freeze)
  s.rubygems_version = "3.4.1".freeze
  s.summary = "Simple, powerful, first-party analytics for Rails".freeze

  s.installed_by_version = "3.4.1" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 7"])
  s.add_runtime_dependency(%q<device_detector>.freeze, [">= 1"])
  s.add_runtime_dependency(%q<safely_block>.freeze, [">= 0.4"])
end
