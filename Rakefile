# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "rspec-background-process"
  gem.homepage = "http://github.com/jpastuszek/rspec-background-process"
  gem.license = "MIT"
  gem.summary = "Cucumber step library useful for managing background processes during testing"
  gem.description = "Cucumber steps for spawning processes and HTTP servers for API testing or lunching stub backend. This steps can pool the background processes between scenarios. Readiness checks can be performed before tests can continue."
  gem.email = "jpastuszek@gmail.com"
  gem.authors = ["Jakub Pastuszek"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rspec-background-process #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
