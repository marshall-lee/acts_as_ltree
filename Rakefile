require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new
RuboCop::RakeTask.new

task :default => :spec

task 'db:setup' do
  if system("createdb acts_as_ltree_test")
    puts 'Database acts_as_ltree_test was successfully created.'
  end

  if system("psql -d acts_as_ltree_test -c 'create extension if not exists ltree'")
    puts 'ltree extension was successfully loaded.'
  end
end
