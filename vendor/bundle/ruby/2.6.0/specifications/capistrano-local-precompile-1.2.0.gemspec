# -*- encoding: utf-8 -*-
# stub: capistrano-local-precompile 1.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "capistrano-local-precompile".freeze
  s.version = "1.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Steve Agalloco, Tom Caflisch".freeze]
  s.date = "2019-02-19"
  s.description = "Local asset-pipeline precompilation for Capstrano".freeze
  s.email = "steve.agalloco@gmail.com, tomcaflisch@gmail.com".freeze
  s.homepage = "https://github.com/spagalloco/capistrano-local-precompile".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3.1".freeze
  s.summary = "Local asset-pipeline precompilation for Capstrano".freeze

  s.installed_by_version = "3.0.3.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<capistrano>.freeze, [">= 3.8"])
    else
      s.add_dependency(%q<capistrano>.freeze, [">= 3.8"])
    end
  else
    s.add_dependency(%q<capistrano>.freeze, [">= 3.8"])
  end
end
