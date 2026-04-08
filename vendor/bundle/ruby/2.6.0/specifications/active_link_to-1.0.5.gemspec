# -*- encoding: utf-8 -*-
# stub: active_link_to 1.0.5 ruby lib

Gem::Specification.new do |s|
  s.name = "active_link_to".freeze
  s.version = "1.0.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Oleg Khabarov".freeze]
  s.date = "2017-08-29"
  s.description = "Helpful method when you need to add some logic that figures out if the link (or more often navigation item) is selected based on the current page or other arbitrary condition".freeze
  s.email = ["oleg@khabarov.ca".freeze]
  s.homepage = "http://github.com/comfy/active_link_to".freeze
  s.rubygems_version = "3.0.3.1".freeze
  s.summary = "ActionView helper to render currently active links".freeze

  s.installed_by_version = "3.0.3.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<actionpack>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<addressable>.freeze, [">= 0"])
    else
      s.add_dependency(%q<actionpack>.freeze, [">= 0"])
      s.add_dependency(%q<addressable>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<actionpack>.freeze, [">= 0"])
    s.add_dependency(%q<addressable>.freeze, [">= 0"])
  end
end
