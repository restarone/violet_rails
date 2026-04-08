# -*- encoding: utf-8 -*-
# stub: airbrussh 1.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "airbrussh".freeze
  s.version = "1.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/mattbrictson/airbrussh/issues", "changelog_uri" => "https://github.com/mattbrictson/airbrussh/releases", "homepage_uri" => "https://github.com/mattbrictson/airbrussh", "source_code_uri" => "https://github.com/mattbrictson/airbrussh" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Matt Brictson".freeze]
  s.bindir = "exe".freeze
  s.date = "2019-10-13"
  s.description = "A replacement log formatter for SSHKit that makes Capistrano output much easier on the eyes. Just add Airbrussh to your Capfile and enjoy concise, useful log output that is easy to read.".freeze
  s.email = ["airbrussh@mattbrictson.com".freeze]
  s.homepage = "https://github.com/mattbrictson/airbrussh".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3.1".freeze
  s.summary = "Airbrussh pretties up your SSHKit and Capistrano output".freeze

  s.installed_by_version = "3.0.3.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sshkit>.freeze, [">= 1.6.1", "!= 1.7.0"])
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.17"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 12.0"])
      s.add_development_dependency(%q<minitest>.freeze, ["~> 5.10"])
      s.add_development_dependency(%q<minitest-reporters>.freeze, ["~> 1.1"])
      s.add_development_dependency(%q<mocha>.freeze, ["~> 1.2"])
    else
      s.add_dependency(%q<sshkit>.freeze, [">= 1.6.1", "!= 1.7.0"])
      s.add_dependency(%q<bundler>.freeze, ["~> 1.17"])
      s.add_dependency(%q<rake>.freeze, ["~> 12.0"])
      s.add_dependency(%q<minitest>.freeze, ["~> 5.10"])
      s.add_dependency(%q<minitest-reporters>.freeze, ["~> 1.1"])
      s.add_dependency(%q<mocha>.freeze, ["~> 1.2"])
    end
  else
    s.add_dependency(%q<sshkit>.freeze, [">= 1.6.1", "!= 1.7.0"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.17"])
    s.add_dependency(%q<rake>.freeze, ["~> 12.0"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.10"])
    s.add_dependency(%q<minitest-reporters>.freeze, ["~> 1.1"])
    s.add_dependency(%q<mocha>.freeze, ["~> 1.2"])
  end
end
