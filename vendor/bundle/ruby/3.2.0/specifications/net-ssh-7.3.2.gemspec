# -*- encoding: utf-8 -*-
# stub: net-ssh 7.3.2 ruby lib

Gem::Specification.new do |s|
  s.name = "net-ssh".freeze
  s.version = "7.3.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/net-ssh/net-ssh/blob/master/CHANGES.txt" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jamis Buck".freeze, "Delano Mandelbaum".freeze, "Mikl\u00F3s Fazekas".freeze]
  s.bindir = "exe".freeze
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDeDCCAmCgAwIBAgIBATANBgkqhkiG9w0BAQsFADBBMQ8wDQYDVQQDDAZuZXRz\nc2gxGTAXBgoJkiaJk/IsZAEZFglzb2x1dGlvdXMxEzARBgoJkiaJk/IsZAEZFgNj\nb20wHhcNMjYwMjE1MTAxNzUyWhcNMjcwMjE1MTAxNzUyWjBBMQ8wDQYDVQQDDAZu\nZXRzc2gxGTAXBgoJkiaJk/IsZAEZFglzb2x1dGlvdXMxEzARBgoJkiaJk/IsZAEZ\nFgNjb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDGJ4TbZ9H+qZ08\npQfJhPJTHaDCyQvCsKTFrL5O9z3tllQ7B/zksMMM+qFBpNYu9HCcg4yBATacE/PB\nqVVyUrpr6lbH/XwoN5ljXm+bdCfmnjZvTCL2FTE6o+bcnaF0IsJyC0Q2B1fbWdXN\n6Off1ZWoUk6We2BIM1bn6QJLxBpGyYhvOPXsYoqSuzDf2SJDDsWFZ8kV5ON13Ohm\nJbBzn0oD8HF8FuYOewwsC0C1q4w7E5GtvHcQ5juweS7+RKsyDcVcVrLuNzoGRttS\nKP4yMn+TzaXijyjRg7gECfJr3TGASaA4bQsILFGG5dAWcwO4OMrZedR7SHj/o0Kf\n3gL7P0axAgMBAAGjezB5MAkGA1UdEwQCMAAwCwYDVR0PBAQDAgSwMB0GA1UdDgQW\nBBQF8qLA7Z4zg0SJGtUbv3eoQ8tjIzAfBgNVHREEGDAWgRRuZXRzc2hAc29sdXRp\nb3VzLmNvbTAfBgNVHRIEGDAWgRRuZXRzc2hAc29sdXRpb3VzLmNvbTANBgkqhkiG\n9w0BAQsFAAOCAQEASsiVybehJLRPztFeFV8+SKa2BwbBSNJoAkhARVJKhpJxCfeY\ngO7Kqb7JCykzb0anb1s6xTrzD03cWRNGE2YaoBLqnzeUqW1LPqVwmcySmnSIGH9F\nDlFYlHaAn3oSqglyDxQx9bLngKatetx+tSfB3bLAb7Tr9PO8/lhBENbjlD4+UUwD\ngApoZuD9pknWDH3KsITgzphswETBdo0hd9aLnRNR3EifD0lUIEit/0Yx6euSxWtI\nufHf4AX2UIkJbh7zCPkiNCqIr7MSWLNFG/9lOlHYsEJM8XujT1ofPobYx6YSFx/C\n7HBrI7UX7awt6UvBZebhcHzyMHxg/B5PVQllPA==\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2026-03-22"
  s.description = "Net::SSH: a pure-Ruby implementation of the SSH2 client protocol. It allows you to write programs that invoke and interact with processes on remote servers, via SSH2.".freeze
  s.email = ["net-ssh@solutious.com".freeze]
  s.extra_rdoc_files = ["LICENSE.txt".freeze, "README.md".freeze]
  s.files = ["LICENSE.txt".freeze, "README.md".freeze]
  s.homepage = "https://github.com/net-ssh/net-ssh".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.4.1".freeze
  s.summary = "Net::SSH: a pure-Ruby implementation of the SSH2 client protocol.".freeze

  s.installed_by_version = "3.4.1" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bcrypt_pbkdf>.freeze, ["~> 1.0"])
  s.add_development_dependency(%q<ed25519>.freeze, ["~> 1.2"])
  s.add_development_dependency(%q<x25519>.freeze, [">= 0"])
  s.add_development_dependency(%q<rbnacl>.freeze, ["~> 7.1"])
  s.add_development_dependency(%q<base64>.freeze, [">= 0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.17"])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.19"])
  s.add_development_dependency(%q<mocha>.freeze, ["~> 2.1.0"])
  s.add_development_dependency(%q<ostruct>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 12.0"])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.28.0"])
end
