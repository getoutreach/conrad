lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'conrad/version'

Gem::Specification.new do |spec|
  spec.name          = 'conrad'
  spec.version       = Conrad::VERSION
  spec.authors       = ['Jonathon Anderson']
  spec.email         = ['jonathon.anderson@outreach.io']

  spec.summary       = 'Tool for auditing events.'
  spec.homepage      = 'https://github.com/getoutreach/conrad'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir['lib/**/*.rb']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'aws-sdk'

  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rubocop', '~> 0.60.0'
end
