require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'cucumber/rake/task'
require 'yard'


YARD::Rake::YardocTask.new
Cucumber::Rake::Task.new(:features)
RSpec::Core::RakeTask.new

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

# Alias for rubygems-test
task test: :spec

task default: :test

