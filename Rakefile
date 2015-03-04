require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

task default: [:spec, :rubocop]

task 'db:setup' do
  db = `psql -c "create database acts_as_ltree_test`
  if db.strip == 'CREATE DATABASE'
    puts 'Database acts_as_ltree_test was successfully created.'
  else
    puts db
  end

  ltree = `psql -d acts_as_ltree_test -c "create extension if not exists ltree`
  if ltree.strip == 'CREATE EXTENSION'
    puts 'Ltree extension was successfully created.'
  else
    puts ltree
  end
end

task :rubocop do
  puts `rubocop`
end
