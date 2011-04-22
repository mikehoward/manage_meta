require 'rake'

# snarf gemspec and set version
x = eval File.new('manage_meta.gemspec').read
manage_meta_version = x.version.to_s

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

desc "commit changes"
task :commit do
  system 'git commit -a -m "checkin"'
end

desc "commit changes and tag as #{manage_meta_version}"
task :tag => :commit do
  system "git tag #{manage_meta_version}"
end

desc "distribute to github and rubygems"
task :distribute => [:tag, :gem] do
  system "gem push manage_meta-#{manage_meta_version}.gem"
  system "git push manage_meta"
end
