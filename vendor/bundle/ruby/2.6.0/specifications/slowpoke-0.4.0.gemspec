# -*- encoding: utf-8 -*-
# stub: slowpoke 0.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "slowpoke".freeze
  s.version = "0.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andrew Kane".freeze]
  s.date = "2022-01-11"
  s.email = "andrew@ankane.org".freeze
  s.homepage = "https://github.com/ankane/slowpoke".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.0.3.1".freeze
  s.summary = "Rack::Timeout enhancements for Rails".freeze

  s.installed_by_version = "3.0.3.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<railties>.freeze, [">= 5.2"])
      s.add_runtime_dependency(%q<actionpack>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<rack-timeout>.freeze, [">= 0.4"])
    else
      s.add_dependency(%q<railties>.freeze, [">= 5.2"])
      s.add_dependency(%q<actionpack>.freeze, [">= 0"])
      s.add_dependency(%q<rack-timeout>.freeze, [">= 0.4"])
    end
  else
    s.add_dependency(%q<railties>.freeze, [">= 5.2"])
    s.add_dependency(%q<actionpack>.freeze, [">= 0"])
    s.add_dependency(%q<rack-timeout>.freeze, [">= 0.4"])
  end
end
