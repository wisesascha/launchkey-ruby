# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'launchkey/version'

Gem::Specification.new do |spec|
  spec.name          = 'launchkey'
  spec.version       = LaunchKey::VERSION
  spec.authors       = ['Gabe Evans']
  spec.email         = ['gabe@ga.be']
  spec.summary       = %q{Passwordless authentication gem using LaunchKey's REST API.}
  spec.description   = %q{LaunchKey is evolving user authentication and killing passwords with physical multi-factor authentication through your smartphone or tablet.}
  spec.homepage      = 'https://launchkey.com/docs/api/overview'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 1.9.3'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport',      '>= 3.1'
  spec.add_dependency 'faraday',            '~> 0.9'
  spec.add_dependency 'faraday_middleware', '~> 0.9'
  spec.add_dependency 'rack',               '>= 1.4'

  # Basic
  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'pry'

  # Docs
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'redcarpet'

  # Testing
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'factory_girl'
  spec.add_development_dependency 'ffaker'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'vcr'
  spec.add_development_dependency 'webmock'

  # Guard
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-bundler'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'guard-yard'
  spec.add_development_dependency 'rb-fsevent'
  spec.add_development_dependency 'rb-inotify'
  spec.add_development_dependency 'terminal-notifier-guard'
end
