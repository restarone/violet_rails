# -*- encoding: utf-8 -*-
# stub: graphql 2.0.5 ruby lib

Gem::Specification.new do |s|
  s.name = "graphql".freeze
  s.version = "2.0.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rmosolgo/graphql-ruby/issues", "changelog_uri" => "https://github.com/rmosolgo/graphql-ruby/blob/master/CHANGELOG.md", "homepage_uri" => "https://graphql-ruby.org", "mailing_list_uri" => "https://tinyletter.com/graphql-ruby", "source_code_uri" => "https://github.com/rmosolgo/graphql-ruby" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Robert Mosolgo".freeze]
  s.date = "2022-03-28"
  s.description = "A plain-Ruby implementation of GraphQL.".freeze
  s.email = ["rdmosolgo@gmail.com".freeze]
  s.homepage = "https://github.com/rmosolgo/graphql-ruby".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4.0".freeze)
  s.rubygems_version = "3.0.3.1".freeze
  s.summary = "A GraphQL language and runtime for Ruby".freeze

  s.installed_by_version = "3.0.3.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<benchmark-ips>.freeze, [">= 0"])
      s.add_development_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0"])
      s.add_development_dependency(%q<memory_profiler>.freeze, [">= 0"])
      s.add_development_dependency(%q<minitest>.freeze, ["~> 5.9.0"])
      s.add_development_dependency(%q<minitest-focus>.freeze, ["~> 1.1"])
      s.add_development_dependency(%q<minitest-reporters>.freeze, ["~> 1.0"])
      s.add_development_dependency(%q<racc>.freeze, ["~> 1.4"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 12"])
      s.add_development_dependency(%q<rubocop>.freeze, ["= 1.12"])
      s.add_development_dependency(%q<jekyll>.freeze, [">= 0"])
      s.add_development_dependency(%q<yard>.freeze, [">= 0"])
      s.add_development_dependency(%q<jekyll-algolia>.freeze, [">= 0"])
      s.add_development_dependency(%q<jekyll-redirect-from>.freeze, [">= 0"])
      s.add_development_dependency(%q<m>.freeze, ["~> 1.5.0"])
      s.add_development_dependency(%q<webrick>.freeze, [">= 0"])
    else
      s.add_dependency(%q<benchmark-ips>.freeze, [">= 0"])
      s.add_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0"])
      s.add_dependency(%q<memory_profiler>.freeze, [">= 0"])
      s.add_dependency(%q<minitest>.freeze, ["~> 5.9.0"])
      s.add_dependency(%q<minitest-focus>.freeze, ["~> 1.1"])
      s.add_dependency(%q<minitest-reporters>.freeze, ["~> 1.0"])
      s.add_dependency(%q<racc>.freeze, ["~> 1.4"])
      s.add_dependency(%q<rake>.freeze, ["~> 12"])
      s.add_dependency(%q<rubocop>.freeze, ["= 1.12"])
      s.add_dependency(%q<jekyll>.freeze, [">= 0"])
      s.add_dependency(%q<yard>.freeze, [">= 0"])
      s.add_dependency(%q<jekyll-algolia>.freeze, [">= 0"])
      s.add_dependency(%q<jekyll-redirect-from>.freeze, [">= 0"])
      s.add_dependency(%q<m>.freeze, ["~> 1.5.0"])
      s.add_dependency(%q<webrick>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<benchmark-ips>.freeze, [">= 0"])
    s.add_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0"])
    s.add_dependency(%q<memory_profiler>.freeze, [">= 0"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.9.0"])
    s.add_dependency(%q<minitest-focus>.freeze, ["~> 1.1"])
    s.add_dependency(%q<minitest-reporters>.freeze, ["~> 1.0"])
    s.add_dependency(%q<racc>.freeze, ["~> 1.4"])
    s.add_dependency(%q<rake>.freeze, ["~> 12"])
    s.add_dependency(%q<rubocop>.freeze, ["= 1.12"])
    s.add_dependency(%q<jekyll>.freeze, [">= 0"])
    s.add_dependency(%q<yard>.freeze, [">= 0"])
    s.add_dependency(%q<jekyll-algolia>.freeze, [">= 0"])
    s.add_dependency(%q<jekyll-redirect-from>.freeze, [">= 0"])
    s.add_dependency(%q<m>.freeze, ["~> 1.5.0"])
    s.add_dependency(%q<webrick>.freeze, [">= 0"])
  end
end
