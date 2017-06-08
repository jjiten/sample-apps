require 'bundler'
Bundler.setup
require 'pp'
require 'rspec/core/rake_task'

require_relative 'spec/spec_helper.rb'

Dir.glob('spec/*/*.rake').each { |r| load r}

desc 'Call install, test, and teardown on all sample apps.'
task :default do
  [:install, :test, :teardown].each { |t| Rake::Task[t].execute }
end

desc 'Call install on all sample apps.'
task :install do
  Rake::Task.tasks().each do |task|
    if task.name.end_with? ":install"
      task.execute
    end
  end
end

desc 'Call test on all sample apps.'
task :test do
  RSpec::Core::RakeTask.new(:spec) do |t|
    ENV['RSPEC_OPTS'] && t.rspec_opts = ENV['RSPEC_OPTS']
    t.pattern = 'spec/*/*_spec.rb'
  end
  Rake::Task["spec"].execute
end

desc 'Call restart on all sample apps.'
task :restart do
  Rake::Task.tasks().each do |task|
    if task.name.end_with? ":restart"
      Rake::Task[task].execute
    end
  end
end

desc 'Call teardown on all sample apps.'
task :teardown do
  Rake::Task.tasks().each do |task|
    if task.name.end_with? ":teardown"
      Rake::Task[task].execute
    end
  end
end

# Wrap calling the spec file for the given app.
def rspec(app)
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = "spec/#{app}/#{app}_spec.rb"
  end
  Rake::Task["spec"].execute
end