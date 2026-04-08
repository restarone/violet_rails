# -*- encoding: utf-8 -*-
# stub: meta-tags 2.23.0 ruby lib

Gem::Specification.new do |s|
  s.name = "meta-tags".freeze
  s.version = "2.23.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/kpumuk/meta-tags/issues/", "changelog_uri" => "https://github.com/kpumuk/meta-tags/blob/main/CHANGELOG.md", "documentation_uri" => "https://rubydoc.info/github/kpumuk/meta-tags/", "homepage_uri" => "https://github.com/kpumuk/meta-tags/", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/kpumuk/meta-tags/" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Dmytro Shteflyuk".freeze]
  s.bindir = "exe".freeze
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDcDCCAligAwIBAgIBATANBgkqhkiG9w0BAQsFADA/MQ8wDQYDVQQDDAZrcHVt\ndWsxFjAUBgoJkiaJk/IsZAEZFgZrcHVtdWsxFDASBgoJkiaJk/IsZAEZFgRpbmZv\nMB4XDTI1MDkyOTE1MDM1M1oXDTI2MDkyOTE1MDM1M1owPzEPMA0GA1UEAwwGa3B1\nbXVrMRYwFAYKCZImiZPyLGQBGRYGa3B1bXVrMRQwEgYKCZImiZPyLGQBGRYEaW5m\nbzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALw2YroZc+IT+rs8NuPu\nc13DelrxrpAgPEu1zuRb3l7WaHRNWA4TyS8Z6Aa1G2O+FdUZNMW1n7IwP/QMJ9Mz\nahRBiTmhik5kasJ9s0h1lq5/hZiycm0o5OtGioUzCkvk+UEMpzMHbLmVSZCzYciy\nNDRDbXB0rLLu1eJk+gKgn6Qf5vj93h1w28BdWdaA7YegtbmipZ+pjmzCQAfPActT\n6uXHG4dSo7Lz9jiFRI5dUizFbGXcRqkQ2b5AB8FFmfcvbqERvzQKBICnybjsKP0N\npJ3vGgO2sh5GvJFOPk1Vlur2nX9ZFznPEP1CEAQ+NFrmKRt355Z5sgOkAojSGnIL\n/1sCAwEAAaN3MHUwCQYDVR0TBAIwADALBgNVHQ8EBAMCBLAwHQYDVR0OBBYEFPa4\nVFc1YOlV1u/7EGTwMCAk8YE9MB0GA1UdEQQWMBSBEmtwdW11a0BrcHVtdWsuaW5m\nbzAdBgNVHRIEFjAUgRJrcHVtdWtAa3B1bXVrLmluZm8wDQYJKoZIhvcNAQELBQAD\nggEBAFz/6+efHFEomTCA8V/eMpzaMkbj04cTmFxm28KiUO1F4vgbSIBx0bsMoJkH\nKI956sPVVJMykwOdDUhRWBrHOVTBCGdkYWdb38KQKfwtkdGd8b/Afrxs5GuPME9r\nTdfDc1aXCAPdLCajhpmuzfa1g8/W7ORdxwNQidYSSPJ5OvcAGSfxTHJsFseHjrBK\n9hdoXZgqc4a5defxoOZFD9Im9AUwFqwR8njCBST6FbCGmHIYNHj2hxbwrU/1I2Kg\npPzkBOwQl2p1ykAEUe7cwoqJcO+1rPeTHjudNqhOfc3VnMA8A7uXOkTtYNVhvApn\noW4hE/8SnZkQm8jzdi0iX9nWxo8=\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2026-03-16"
  s.description = "Rails helpers for HTML metadata such as titles, descriptions, canonical links, robots directives, and social tags.".freeze
  s.email = ["kpumuk@kpumuk.info".freeze]
  s.homepage = "https://github.com/kpumuk/meta-tags".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0.0".freeze)
  s.rubygems_version = "3.4.1".freeze
  s.summary = "Collection of metadata helpers for Ruby on Rails.".freeze

  s.installed_by_version = "3.4.1" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<actionpack>.freeze, [">= 6.0.0"])
  s.add_development_dependency(%q<appraisal>.freeze, ["~> 2.5.0"])
  s.add_development_dependency(%q<railties>.freeze, [">= 3.2.0"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.13.0"])
  s.add_development_dependency(%q<rspec-html-matchers>.freeze, ["~> 0.10.0"])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.22.0"])
  s.add_development_dependency(%q<steep>.freeze, ["~> 1.10.0"])
  s.add_development_dependency(%q<rubocop-rake>.freeze, ["~> 0.6"])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, ["~> 3.4"])
  s.add_development_dependency(%q<standard>.freeze, ["~> 1.31"])
  s.add_development_dependency(%q<standard-rails>.freeze, ["~> 1.6"])
  s.add_development_dependency(%q<rspec_junit_formatter>.freeze, ["~> 0.6.0"])
end
