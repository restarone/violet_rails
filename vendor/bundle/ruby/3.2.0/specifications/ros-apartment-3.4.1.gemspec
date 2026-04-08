# -*- encoding: utf-8 -*-
# stub: ros-apartment 3.4.1 ruby lib

Gem::Specification.new do |s|
  s.name = "ros-apartment".freeze
  s.version = "3.4.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "github_repo" => "ssh://github.com/rails-on-services/apartment", "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ryan Brunner".freeze, "Brad Robertson".freeze, "Rui Baltazar".freeze, "Mauricio Novelo".freeze]
  s.date = "1980-01-02"
  s.description = "Apartment allows Rack applications to deal with database multitenancy through ActiveRecord".freeze
  s.email = ["ryan@influitive.com".freeze, "brad@influitive.com".freeze, "rui.p.baltazar@gmail.com".freeze, "mauricio@campusesp.com".freeze]
  s.homepage = "https://github.com/rails-on-services/apartment".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1".freeze)
  s.rubygems_version = "3.4.1".freeze
  s.summary = "A Ruby gem for managing database multitenancy. Apartment Gem drop in replacement".freeze

  s.installed_by_version = "3.4.1" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 7.0.0", "< 8.2"])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 7.0.0", "< 8.2"])
  s.add_runtime_dependency(%q<parallel>.freeze, ["< 2.0"])
  s.add_runtime_dependency(%q<public_suffix>.freeze, [">= 2.0.5", "< 7"])
  s.add_runtime_dependency(%q<rack>.freeze, [">= 1.3.6", "< 4.0"])
end
