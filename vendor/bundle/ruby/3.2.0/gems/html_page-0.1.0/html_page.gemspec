# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "html_page/version"

Gem::Specification.new do |spec|
  spec.name          = "html_page"
  spec.version       = HtmlPage::VERSION
  spec.authors       = ["Sean Doyle"]
  spec.email         = ["sean.p.doyle24@gmail.com"]

  spec.summary       = %q{Inject content into an existing HTML document.}
  spec.description   = %q{Inject content into an existing HTML document.}
  spec.homepage      = "https://github.com/seanpdoyle/html_page"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
