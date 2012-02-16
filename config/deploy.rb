set :application, "etengine"
set :stage, :production
set :server_type, 'production'

task :production do
  set :domain, "et-engine.com"
  set :branch, "production"
  set :application_key, "etengine"
  set :deploy_to, "/home/ubuntu/apps/#{application_key}"
  set :db_host, "etm.cr6sxqj0itls.eu-west-1.rds.amazonaws.com"
  set :db_pass, "Energy2.0"
  set :db_name, application_key
  set :db_user, application_key
  set :airbrake_key, "c7aceee5954aea78f93e7ca4b22439c7"
  server domain, :web, :app, :db, :primary => true
end

task :staging do
  warn "\n\n# DEPRECATED *staging* \n#\n# cap staging deploy is now cap *beta* deploy\n\n"
  exit
end

task :beta do
  # set :domain, "beta.et-engine.com"
  set :domain, "ec2-176-34-196-168.eu-west-1.compute.amazonaws.com"
  set :branch, "unicorn"
  set :application_key, "etengine"
  set :deploy_to, "/u/apps/etengine"
  set :db_host, "etm.cr6sxqj0itls.eu-west-1.rds.amazonaws.com"
  set :db_pass, "r8ZPP7pQTDTBha"
  set :db_name, 'etengine_staging'
  set :db_user, 'etengine_staging'
  set :airbrake_key, "e483e275c8425821ec21580e0ffefe9d"
  server domain, :web, :app, :db, :primary => true
end

task :edge do
  set :domain, "edge.et-engine.com"
  set :branch, "staging"
  set :application_key, "#{application}_edge"
  set :deploy_to, "/home/ubuntu/apps/#{application_key}"
  set :db_host, "etm.cr6sxqj0itls.eu-west-1.rds.amazonaws.com"
  set :db_pass, "lVtSsSv43KooQE"
  set :db_name, application_key
  set :db_user, application_key
  set :airbrake_key, "e483e275c8425821ec21580e0ffefe9d"
  server domain, :web, :app, :db, :primary => true
end

set :user, 'ubuntu'

set :scm, :git
set :repository,  "git@github.com:dennisschoenmakers/etengine.git"
set :deploy_via, :remote_cache
set :chmod755, "app config db lib public vendor script script/* public/disp*"  	# Some files that will need proper permissions set :use_sudo, false
ssh_options[:forward_agent] = true
set :use_sudo,     false
set :local_db_name, 'etengine_dev'
set :bundle_flags, '--deployment --quiet --binstubs --shebang ruby-local-exec'

