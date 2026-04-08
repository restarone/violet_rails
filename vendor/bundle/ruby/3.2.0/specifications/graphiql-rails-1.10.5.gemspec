# -*- encoding: utf-8 -*-
# stub: graphiql-rails 1.10.5 ruby lib

Gem::Specification.new do |s|
  s.name = "graphiql-rails".freeze
  s.version = "1.10.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Robert Mosolgo".freeze]
  s.date = "2025-05-16"
  s.description = "Use the GraphiQL IDE for GraphQL with Ruby on Rails. This gem includes an engine, a controller and a view for integrating GraphiQL with your app.".freeze
  s.email = ["rdmosolgo@gmail.com".freeze]
  s.homepage = "http://github.com/rmosolgo/graphiql-rails".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.1.0".freeze)
  s.rubygems_version = "3.4.1".freeze
  s.summary = "A mountable GraphiQL endpoint for Rails".freeze

  s.installed_by_version = "3.4.1" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<railties>.freeze, [">= 0"])
  s.add_development_dependency(%q<rails>.freeze, [">= 0"])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
  s.add_development_dependency(%q<codeclimate-test-reporter>.freeze, ["~> 0.4"])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5"])
  s.add_development_dependency(%q<minitest-focus>.freeze, ["~> 1.1"])
  s.add_development_dependency(%q<minitest-reporters>.freeze, ["~> 1.0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<puma>.freeze, [">= 0"])
end
