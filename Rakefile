require 'rubygems'
require "bundler/gem_tasks"

require 'rspec'
require 'rspec/core/rake_task'

desc "Run the specs for wesabot"
RSpec::Core::RakeTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

task :cruise => :spec
task :default => :spec