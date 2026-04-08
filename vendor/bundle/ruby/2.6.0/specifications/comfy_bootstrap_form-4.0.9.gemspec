# -*- encoding: utf-8 -*-
# stub: comfy_bootstrap_form 4.0.9 ruby lib

Gem::Specification.new do |s|
  s.name = "comfy_bootstrap_form".freeze
  s.version = "4.0.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Oleg Khabarov".freeze]
  s.bindir = "exe".freeze
  s.date = "2020-02-16"
  s.description = "bootstrap_form is a Rails form builder that automatically wraps form elements in Bootstrap 4 markup".freeze
  s.email = ["oleg@khabarov.ca".freeze]
  s.homepage = "https://github.com/comfy/comfy-bootstrap-form".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.0.3.1".freeze
  s.summary = "Rails form builder for Bootstrap 4 markup that works!".freeze

  s.installed_by_version = "3.0.3.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rails>.freeze, [">= 5.0.0"])
    else
      s.add_dependency(%q<rails>.freeze, [">= 5.0.0"])
    end
  else
    s.add_dependency(%q<rails>.freeze, [">= 5.0.0"])
  end
end
