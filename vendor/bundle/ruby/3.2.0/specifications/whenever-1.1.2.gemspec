# -*- encoding: utf-8 -*-
# stub: whenever 1.1.2 ruby lib

Gem::Specification.new do |s|
  s.name = "whenever".freeze
  s.version = "1.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/javan/whenever/blob/main/CHANGELOG.md", "homepage_uri" => "https://github.com/javan/whenever", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/javan/whenever" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Javan Makhmali".freeze]
  s.date = "1980-01-02"
  s.description = "Clean ruby syntax for writing and deploying cron jobs.".freeze
  s.email = ["javan@javan.us".freeze]
  s.executables = ["whenever".freeze, "wheneverize".freeze]
  s.files = ["bin/whenever".freeze, "bin/wheneverize".freeze]
  s.homepage = "https://github.com/javan/whenever".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "3.4.1".freeze
  s.summary = "Cron jobs in ruby.".freeze

  s.installed_by_version = "3.4.1" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<chronic>.freeze, [">= 0.6.3"])
end
