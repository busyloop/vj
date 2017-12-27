
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vj/version'

Gem::Specification.new do |spec|
  spec.name          = 'vj'
  spec.version       = Vj::VERSION
  spec.authors       = ['moe']
  spec.email         = ['moe@busyloop.net']

  spec.summary       = 'JSON humanizer.'
  spec.description   = 'JSON humanizer.'
  spec.homepage      = 'https://github.com/busyloop/vj'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'oj'
  spec.add_dependency 'optix'
  spec.add_dependency 'paint'

  spec.add_development_dependency 'bump'
  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'bundler-audit'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rubocop'
end
