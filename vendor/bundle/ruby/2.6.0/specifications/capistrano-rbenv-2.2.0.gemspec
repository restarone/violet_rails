# -*- encoding: utf-8 -*-
# stub: capistrano-rbenv 2.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "capistrano-rbenv".freeze
  s.version = "2.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/capistrano/rbenv/releases" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Kir Shatrov".freeze, "Yamashita Yuu".freeze]
  s.date = "2020-07-12"
  s.description = "rbenv integration for Capistrano".freeze
  s.email = ["shatrov@me.com".freeze, "yamashita@geishatokyo.com".freeze]
  s.homepage = "https://github.com/capistrano/rbenv".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3.1".freeze
  s.summary = "rbenv integration for Capistrano".freeze

  s.installed_by_version = "3.0.3.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<capistrano>.freeze, ["~> 3.1"])
      s.add_runtime_dependency(%q<sshkit>.freeze, ["~> 1.3"])
      s.add_development_dependency(%q<danger>.freeze, [">= 0"])
    else
      s.add_dependency(%q<capistrano>.freeze, ["~> 3.1"])
      s.add_dependency(%q<sshkit>.freeze, ["~> 1.3"])
      s.add_dependency(%q<danger>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<capistrano>.freeze, ["~> 3.1"])
    s.add_dependency(%q<sshkit>.freeze, ["~> 1.3"])
    s.add_dependency(%q<danger>.freeze, [">= 0"])
  end
end
