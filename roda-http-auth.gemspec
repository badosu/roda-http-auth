# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'roda/plugins/http_auth/version'

Gem::Specification.new do |spec|
  spec.name          = "roda-http-auth"
  spec.version       = Roda::RodaPlugins::HttpAuth::VERSION
  spec.authors       = ["Amadeus Folego"]
  spec.email         = ["amadeusfolego@gmail.com"]

  spec.summary       = %q{Add http authorization methods to Roda}
  spec.description   = %q{Add http authorization methods to Roda}
  spec.homepage      = "https://github.com/badosu/roda-http-auth"

  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec)/}) }
  spec.require_paths = ["lib"]

  spec.add_dependency "roda", ">= 2.0", "< 4.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 12.3"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "tilt"
end
