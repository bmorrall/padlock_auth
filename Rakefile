require "bundler/setup"

require "bundler/gem_tasks"

require "yard"
YARD::Rake::YardocTask.new do |t|
  t.files = ["lib/**/*.rb"]
end

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

require "standard/rake"

task default: %i[
  spec
  standard
]
