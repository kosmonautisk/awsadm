# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'awsadm/version'

Gem::Specification.new do |spec|
  spec.name          = "awsadm"
  spec.version       = Awsadm::VERSION
  spec.authors       = ["Jimmy Thelander"]
  spec.email         = ["jimmy.thelander@gmail.com"]
  spec.summary       = %q{EXPERIMENTAL: Command-line tool for AWS resources.}
  spec.description   = %q{Manage your AWS resources from the command-line.}
  spec.homepage      = "https://github.com/thelander/awsadm"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "thor"
  spec.add_dependency "aws-sdk"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry"
end
