# -*- encoding: utf-8 -*-
# stub: html_page 0.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "html_page".freeze
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sean Doyle".freeze]
  s.bindir = "exe".freeze
  s.date = "2015-12-13"
  s.description = "Inject content into an existing HTML document.".freeze
  s.email = ["sean.p.doyle24@gmail.com".freeze]
  s.homepage = "https://github.com/seanpdoyle/html_page".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.1".freeze
  s.summary = "Inject content into an existing HTML document.".freeze

  s.installed_by_version = "3.4.1" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.10"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
end
