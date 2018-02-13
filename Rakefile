require "bundler/gem_tasks"
require "rake/testtask"
require "yard"

require "rubocop/rake_task"
RuboCop::RakeTask.new

Rake::TestTask.new :test do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

YARD::Rake::YardocTask.new do |t|
 t.files   = ['lib/**/*.rb']   # optional
 t.options = ['--output-dir', 'docs/api'] # optional
 t.stats_options = ['--list-undoc']         # optional
end

task :faster do
  ENV["FASTER_TESTS"] = "true"
end

task :default => [:test, :rubocop, :yard]
