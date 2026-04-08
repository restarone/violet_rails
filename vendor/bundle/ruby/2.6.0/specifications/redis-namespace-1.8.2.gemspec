# -*- encoding: utf-8 -*-
# stub: redis-namespace 1.8.2 ruby lib

Gem::Specification.new do |s|
  s.name = "redis-namespace".freeze
  s.version = "1.8.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/resque/redis-namespace/issues", "changelog_uri" => "https://github.com/resque/redis-namespace/blob/master/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/gems/redis-namespace/1.8.2", "source_code_uri" => "https://github.com/resque/redis-namespace/tree/v1.8.2" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Chris Wanstrath".freeze, "Terence Lee".freeze, "Steve Klabnik".freeze, "Ryan Biesemeyer".freeze]
  s.date = "2022-03-07"
  s.description = "Adds a Redis::Namespace class which can be used to namespace calls\nto Redis. This is useful when using a single instance of Redis with\nmultiple, different applications.\n".freeze
  s.email = ["chris@ozmm.org".freeze, "hone02@gmail.com".freeze, "steve@steveklabnik.com".freeze, "me@yaauie.com".freeze]
  s.homepage = "https://github.com/resque/redis-namespace".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4".freeze)
  s.rubygems_version = "3.0.3.1".freeze
  s.summary = "Namespaces Redis commands.".freeze

  s.installed_by_version = "3.0.3.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<redis>.freeze, [">= 3.0.4"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.7"])
      s.add_development_dependency(%q<rspec-its>.freeze, [">= 0"])
    else
      s.add_dependency(%q<redis>.freeze, [">= 3.0.4"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.7"])
      s.add_dependency(%q<rspec-its>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<redis>.freeze, [">= 3.0.4"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.7"])
    s.add_dependency(%q<rspec-its>.freeze, [">= 0"])
  end
end
