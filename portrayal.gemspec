lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'portrayal/version'

Gem::Specification.new do |spec|
  spec.name    = 'portrayal'
  spec.version = Portrayal::VERSION
  spec.authors = ['Maxim Chernyak']
  spec.email   = ['madfancier@gmail.com']

  spec.summary     = 'A minimal builder for struct-like classes'
  spec.description = 'Inspired by dry-initializer and virtus, portrayal is a minimalist gem (~120 loc, no dependencies) that takes a somewhat different approach to building struct-like classes. It steps away from types, coersion, and writer methods in favor of encouraging well-designed constructors. Read more in the Philosophy section of the README.'
  spec.homepage    = 'https://github.com/scottscheapflights/portrayal'
  spec.license     = 'Apache-2.0'

  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^spec/}) }
  end
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'pry', '~> 0.12'
end
