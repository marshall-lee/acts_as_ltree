# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'acts_as_ltree/version'

Gem::Specification.new do |spec|
  spec.name          = "acts_as_ltree"
  spec.version       = ActsAsLtree::VERSION
  spec.authors       = ["Vladimir Kochnev"]
  spec.email         = ["hashtable@yandex.ru"]

  spec.summary       = %q{Yet another hierarchy plugin for ActiveRecord using PostgreSQL's ltree}
  spec.homepage      = "https://github.com/marshall-lee/acts_as_ltree"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "arel", "~> 6.0"
  spec.add_dependency "activerecord", "~> 4.2"
  spec.add_dependency "activesupport", "~> 4.2"
  spec.add_dependency "railties", "~> 4.2"

  unless RUBY_PLATFORM =~ /java/
    spec.add_dependency "pg", ">= 0.15.0"
  else
    spec.add_dependency "activerecord-jdbcpostgresql-adapter", ">= 1.3.0"
  end

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "with_model", "~> 1.2.1"
  spec.add_development_dependency "rspec", "~> 3.2.0"
  spec.add_development_dependency "database_cleaner", "~> 1.4.0"
  spec.add_development_dependency 'rubocop' 
end
