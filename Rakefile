require File.expand_path('../config/application', __FILE__)
require 'rake'

Etm::Application.load_tasks

require 'rake'
require 'rake/testtask'
require 'rdoc/task'
require 'yard'

# needed for rake yard
YARD::Rake::YardocTask.new do |t|
end

desc "Runs annotate on all models, incl. app/pkg"
task :annotate do
  system "annotate -d"
  system "annotate -p before -e tests, fixtures"
end
