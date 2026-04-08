# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'apartment/sidekiq/version'

Gem::Specification.new do |spec|
  spec.name          = "ros-apartment-sidekiq"
  spec.version       = Apartment::Sidekiq::VERSION
  spec.authors       = ["Brad Robertson", "Rui Baltazar"]
  spec.email         = ["brad@influitive.com", "rui.p.baltazar@gmail.com"]
  spec.description   = %q{Enable Multi-tenant supported jobs to work with Sidekiq background worker}
  spec.summary       = %q{Sidekiq support for Ros Apartment}
  spec.homepage      = "https://github.com/rails-on-services/apartment-sidekiq"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'minitest'

  spec.add_dependency 'ros-apartment', '>= 1.0'
  spec.add_dependency 'sidekiq', '>= 2.11'
end
