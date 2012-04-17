require File.expand_path('../config/application', __FILE__)
require 'rake'

Etm::Application.load_tasks

require 'rake'
require 'rake/testtask'
require 'rdoc/task'

require 'yard'

YARD::Config.load_plugin('yard-tomdoc')
YARD::Rake::YardocTask.new do |t|
  # overwriting default output is used by capistrano, so we can generate
  # documentation in a shared directory.
  t.options = ["-o #{ENV['YARD_OUTPUT']}"] if ENV['YARD_OUTPUT'] 
  t.files   = ['app/models/gql/**/*.rb', 'app/models/qernel/**/*.rb']   # optional
end

desc "Runs annotate on all models, incl. app/pkg"
task :annotate do
  system "annotate -d"
  system "annotate -p before -e tests, fixtures"
end
