# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "comfy_bootstrap_form/version"

Gem::Specification.new do |s|
  s.name        = "comfy_bootstrap_form"
  s.version     = ComfyBootstrapForm::VERSION
  s.authors     = ["Oleg Khabarov"]
  s.email       = ["oleg@khabarov.ca"]
  s.homepage    = "https://github.com/comfy/comfy-bootstrap-form"
  s.summary     = "Rails form builder for Bootstrap 4 markup that works!"
  s.description = "bootstrap_form is a Rails form builder that automatically wraps "\
                  "form elements in Bootstrap 4 markup"
  s.license     = "MIT"

  s.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|demo)/})
  end

  s.bindir        = "exe"
  s.require_paths = ["lib"]

  s.required_ruby_version = ">= 2.3.0"

  s.add_dependency "rails", ">= 5.0.0"
end
