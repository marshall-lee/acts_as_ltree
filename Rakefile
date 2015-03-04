require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new
RuboCop::RakeTask.new

task :default => [:spec, :rubocop]

task 'db:setup' do
  base_cmd = "psql"

  username = ENV['POSTGRES_USERNAME']
  base_cmd << " -U #{username}" if username

  db = `#{base_cmd} -c "create database acts_as_ltree_test"`
  if db.strip == 'CREATE DATABASE'
    puts 'Database acts_as_ltree_test was successfully created.'
  else
    puts db
  end

  ltree = `#{base_cmd} -d acts_as_ltree_test -c "create extension if not exists ltree"`
  if ltree.strip == 'CREATE EXTENSION'
    puts 'ltree extension was successfully created.'
  else
    puts ltree
  end
end
