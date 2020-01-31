
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'better_error/version'

Gem::Specification.new do |spec|
  spec.name          = "better_error"
  spec.version       = ::BetterError::VERSION
  spec.authors       = ["Joao Fernandes"]
  spec.email         = ["joao@salsify.com"]

  spec.summary       = %q{A StandardError with extra goodness.}
  spec.homepage      = "https://github.com/salsify/better_error."
  spec.license       = "MIT"

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-byebug"

  spec.add_dependency "activesupport", ">= 4"
  spec.add_dependency "liquid", "~> 4.0"
end
