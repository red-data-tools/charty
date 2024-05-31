require "bundler/gem_tasks"
require "rake/testtask"

desc "Run tests"
task :test do
  verbose = ""
  verbose = "-v" if ENV["VERBOSE"].to_i > 0
  ruby("test/run.rb #{verbose}".strip)
end

task default: :test
