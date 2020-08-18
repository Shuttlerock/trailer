# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'shuttlerock_tracer/version'

Gem::Specification.new do |spec|
  spec.name                  = 'shuttlerock_tracer'
  spec.version               = ShuttlerockTracer::VERSION
  spec.authors               = ['Dave Perrett']
  spec.email                 = ['dave@recurser.com']
  spec.summary               = 'Distributed tracing for Shuttlerock services'
  spec.description           = 'Provides a wrapper around AWS X-Ray for application tracing.'
  spec.homepage              = 'https://github.com/Shuttlerock/shuttlerock_tracer'
  spec.required_ruby_version = '>= 2.6.0'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |file| file.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |file| File.basename(file) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '>= 1.17'
  spec.add_development_dependency 'rake', '>= 12.3.3'
  spec.add_development_dependency 'rspec', '>= 3.0'
end
