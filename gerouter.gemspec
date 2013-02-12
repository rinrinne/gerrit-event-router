# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ger/version'

Gem::Specification.new do |gem|
  gem.name          = "gerouter"
  gem.version       = GerritEventRouter::VERSION
  gem.authors       = ["rinrinne"]
  gem.email         = ["rinrin.ne@gmail.com"]
  gem.description   = %q{Server application for routing gerrit events to message broker}
  gem.summary       = %q{Gerrit Event Router}
  gem.homepage      = "https://github.com/rinrinne/gerrit-event-router/"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency("eventmachine")
  gem.add_runtime_dependency("em-ssh")
  gem.add_runtime_dependency("amqp")
end
