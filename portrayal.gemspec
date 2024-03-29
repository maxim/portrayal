require_relative 'lib/portrayal/version'

Gem::Specification.new do |spec|
  spec.name    = 'portrayal'
  spec.version = Portrayal::VERSION
  spec.authors = ['Max Chernyak']
  spec.email   = ['hello@max.engineer']

  spec.summary     = 'A minimal builder for struct-like classes'
  spec.description = 'Inspired by dry-initializer and virtus, portrayal is a minimalist gem that takes a somewhat different approach to building struct-like classes. It steps away from types, coersion, and writer methods in favor of encouraging well-designed constructors. Read more in the Philosophy section of the README.'
  spec.homepage    = 'https://github.com/maxim/portrayal'
  spec.license     = 'Apache-2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = 'https://github.com/maxim/portrayal/blob/main/CHANGELOG.md'

  spec.required_ruby_version = Gem::Requirement.new('>= 2.4.0')
  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^spec/}) }
  end
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'pry', '~> 0.14'
  spec.add_development_dependency 'benchmark-ips', '~> 2.11'
end
