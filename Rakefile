require 'rake'

task :default => :test

desc "Run ManageMeta unit tests"
task :test do
  require './test/manage_meta_test'
end

desc "run rdoc to create doc"
task :doc do
  system 'rdoc'
end

desc "build gem"
task :gem do
  system 'gem build manage_meta.gemspec'
end
