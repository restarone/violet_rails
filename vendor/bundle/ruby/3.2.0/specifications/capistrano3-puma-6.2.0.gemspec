# -*- encoding: utf-8 -*-
# stub: capistrano3-puma 6.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "capistrano3-puma".freeze
  s.version = "6.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Abdelkader Boudih".freeze]
  s.date = "1980-01-02"
  s.description = "Puma integration for Capistrano 3".freeze
  s.email = ["Terminale@gmail.com".freeze]
  s.homepage = "https://github.com/seuros/capistrano-puma".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "\n    Version 6.0.0 is a major release. Please see README.md, breaking changes are listed in CHANGELOG.md\n  ".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.4.1".freeze
  s.summary = "Puma integration for Capistrano".freeze

  s.installed_by_version = "3.4.1" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<capistrano>.freeze, ["~> 3.7"])
  s.add_runtime_dependency(%q<capistrano-bundler>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<puma>.freeze, [">= 5.1", "< 7.0"])
end
