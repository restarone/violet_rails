# -*- encoding: utf-8 -*-
# stub: ros-apartment-sidekiq 1.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ros-apartment-sidekiq".freeze
  s.version = "1.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Brad Robertson".freeze, "Rui Baltazar".freeze]
  s.date = "2020-01-02"
  s.description = "Enable Multi-tenant supported jobs to work with Sidekiq background worker".freeze
  s.email = ["brad@influitive.com".freeze, "rui.p.baltazar@gmail.com".freeze]
  s.homepage = "https://github.com/rails-on-services/apartment-sidekiq".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3.1".freeze
  s.summary = "Sidekiq support for Ros Apartment".freeze

  s.installed_by_version = "3.0.3.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.6"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<ros-apartment>.freeze, [">= 1.0"])
      s.add_runtime_dependency(%q<sidekiq>.freeze, [">= 2.11"])
    else
      s.add_dependency(%q<bundler>.freeze, ["~> 1.6"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<minitest>.freeze, [">= 0"])
      s.add_dependency(%q<ros-apartment>.freeze, [">= 1.0"])
      s.add_dependency(%q<sidekiq>.freeze, [">= 2.11"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 1.6"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<minitest>.freeze, [">= 0"])
    s.add_dependency(%q<ros-apartment>.freeze, [">= 1.0"])
    s.add_dependency(%q<sidekiq>.freeze, [">= 2.11"])
  end
end
