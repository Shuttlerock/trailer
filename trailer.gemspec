# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trailer/version'

Gem::Specification.new do |spec|
  spec.name                          = 'trailer'
  spec.version                       = Trailer::VERSION
  spec.authors                       = ['Dave Perrett']
  spec.email                         = ['hello@daveperrett.com']
  spec.summary                       = 'Application tracing for distributed services'
  spec.description                   = 'Provides a framework for tracing events within a service, or across multiple services.'
  spec.homepage                      = 'https://github.com/Shuttlerock/trailer'
  spec.required_ruby_version         = '>= 2.6.0'
  spec.licenses                      = ['MIT']
  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |file| file.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |file| File.basename(file) }
  spec.require_paths = ['lib']

  spec.add_dependency 'aws-sdk-cloudwatchlogs', '>= 1.34.0'
  spec.add_dependency 'concurrent-ruby', '>= 1.1.7'
  spec.add_dependency 'request_store', '>= 1.2.0'
  spec.add_dependency 'request_store-sidekiq', '~> 0.1'

  spec.add_development_dependency 'bundle-audit'
  spec.add_development_dependency 'bundler', '>= 1.17'
  spec.add_development_dependency 'bundler-leak'
  spec.add_development_dependency 'dotenv'
  spec.add_development_dependency 'rake', '>= 12.3.3'
  spec.add_development_dependency 'rspec', '>= 3.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-performance'
  spec.add_development_dependency 'rubocop-rspec'
end
