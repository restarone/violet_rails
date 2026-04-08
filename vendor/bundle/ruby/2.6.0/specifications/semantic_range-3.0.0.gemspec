# -*- encoding: utf-8 -*-
# stub: semantic_range 3.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "semantic_range".freeze
  s.version = "3.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andrew Nesbitt".freeze]
  s.date = "2021-03-04"
  s.email = ["andrewnez@gmail.com".freeze]
  s.homepage = "https://libraries.io/github/librariesio/semantic_range".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3.1".freeze
  s.summary = "node-semver rewritten in ruby, for comparison and inclusion of semantic versions and ranges".freeze

  s.installed_by_version = "3.0.3.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.4"])
    else
      s.add_dependency(%q<rspec>.freeze, ["~> 3.4"])
    end
  else
    s.add_dependency(%q<rspec>.freeze, ["~> 3.4"])
  end
end
