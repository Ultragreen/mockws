# frozen_string_literal: true

Gem::Specification.new do |spec|
    spec.name          = 'mockws'
    spec.version       = `cat VERSION`.chomp
    spec.authors       = ['Camille Paquet', 'Romain GEORGES', 'Pierre Alphonse']
    spec.email         = ['gems@ultragreen.net']
  
    spec.summary       = 'MockWS : Web services  mocking utility'
    spec.description   = 'MockWS : Web services  mocking utility'
    spec.homepage      = 'https://github.com/Ultragreen/mockws'
    spec.license       = 'MIT'
    spec.required_ruby_version = Gem::Requirement.new('>= 2.6.0')
  
    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = spec.homepage
    spec.metadata['changelog_uri'] = spec.homepage
  
    # Specify which files should be added to the gem when it is released.
    # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
    spec.files = Dir.chdir(File.expand_path(__dir__)) do
      `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
    end
    spec.bindir        = 'exe'
    spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
    spec.require_paths = ['lib']
  
    spec.add_development_dependency 'code_statistics', '~> 0.2.13'
    spec.add_development_dependency 'rake', '~> 12.0'
    spec.add_development_dependency 'roodi', '~> 5.0'
    spec.add_development_dependency 'rspec', '~> 3.0'
    spec.add_development_dependency 'rubocop', '~> 1.32'
    spec.add_development_dependency 'version', '~> 1.1'
    spec.add_development_dependency 'yard', '~> 0.9.27'
    spec.add_development_dependency 'yard-rspec', '~> 0.1'
    spec.metadata['rubygems_mfa_required'] = 'false'
    spec.add_dependency 'carioca', '~> 2.1'
    spec.add_dependency 'thor', '~> 1.2'
    spec.add_dependency 'thin', '~> 1.8'
    spec.add_dependency 'sinatra', '~> 3.1'
  end