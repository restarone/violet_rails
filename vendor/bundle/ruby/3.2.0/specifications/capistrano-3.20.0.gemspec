# -*- encoding: utf-8 -*-
# stub: capistrano 3.20.0 ruby lib

Gem::Specification.new do |s|
  s.name = "capistrano".freeze
  s.version = "3.20.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/capistrano/capistrano/issues", "changelog_uri" => "https://github.com/capistrano/capistrano/releases", "documentation_uri" => "https://capistranorb.com/", "homepage_uri" => "https://capistranorb.com/", "source_code_uri" => "https://github.com/capistrano/capistrano" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Tom Clements".freeze, "Lee Hambley".freeze]
  s.date = "1980-01-02"
  s.description = "Capistrano is a utility and framework for executing commands in parallel on multiple remote machines, via SSH.".freeze
  s.email = ["seenmyfate@gmail.com".freeze, "lee.hambley@gmail.com".freeze]
  s.executables = ["cap".freeze, "capify".freeze]
  s.files = ["bin/cap".freeze, "bin/capify".freeze]
  s.homepage = "https://capistranorb.com/".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.4.1".freeze
  s.summary = "Capistrano - Welcome to easy deployment with Ruby over SSH".freeze

  s.installed_by_version = "3.4.1" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<airbrussh>.freeze, [">= 1.0.0"])
  s.add_runtime_dependency(%q<i18n>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<rake>.freeze, [">= 10.0.0"])
  s.add_runtime_dependency(%q<sshkit>.freeze, [">= 1.9.0"])
end
