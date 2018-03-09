# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "opencensus/version"

Gem::Specification.new do |spec|
  spec.name          = "opencensus"
  spec.version       = OpenCensus::VERSION
  spec.authors       = ["Jeff Ching", "Daniel Azuma"]
  spec.email         = ["chingor@google.com", "dazuma@google.com"]

  spec.summary       = %q{A stats collection and distributed tracing framework}
  spec.description   = %q{A stats collection and distributed tracing framework}
  spec.homepage      = "https://github.com/census-instrumentation/opencensus-ruby"
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.2.0"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-focus", "~> 1.1"
  spec.add_development_dependency "faraday", "~> 0.13"
  spec.add_development_dependency "rails", "~> 5.1.4"
  spec.add_development_dependency "rubocop", "~> 0.52"
  spec.add_development_dependency "yard", "~> 0.9"
  spec.add_development_dependency "yard-doctest", "~> 0.1.6"
end
