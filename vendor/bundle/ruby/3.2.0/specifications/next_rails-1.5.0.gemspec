# -*- encoding: utf-8 -*-
# stub: next_rails 1.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "next_rails".freeze
  s.version = "1.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ernesto Tagwerker".freeze, "Luis Sagastume".freeze]
  s.bindir = "exe".freeze
  s.date = "2026-04-02"
  s.description = "A set of handy tools to upgrade your Rails application and keep it up to date".freeze
  s.email = ["ernesto@ombulabs.com".freeze, "luis@ombulabs.com".freeze]
  s.executables = ["bundle_report".freeze, "deprecations".freeze, "gem-next-diff".freeze, "next".freeze, "next.sh".freeze, "next_rails".freeze]
  s.files = ["exe/bundle_report".freeze, "exe/deprecations".freeze, "exe/gem-next-diff".freeze, "exe/next".freeze, "exe/next.sh".freeze, "exe/next_rails".freeze]
  s.homepage = "https://github.com/fastruby/next_rails".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0".freeze)
  s.rubygems_version = "3.4.1".freeze
  s.summary = "A toolkit to upgrade your next Rails application".freeze

  s.installed_by_version = "3.4.1" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rainbow>.freeze, [">= 3"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.16", "< 3.0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.17.1"])
  s.add_development_dependency(%q<timecop>.freeze, ["~> 0.9.1"])
  s.add_development_dependency(%q<byebug>.freeze, [">= 0"])
  s.add_development_dependency(%q<rexml>.freeze, ["= 3.2.5"])
  s.add_development_dependency(%q<webmock>.freeze, ["= 3.16.2"])
  s.add_development_dependency(%q<base64>.freeze, [">= 0"])
end
