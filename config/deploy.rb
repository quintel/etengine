set :application, "etengine"
set :application_key, "etengine"
set :stage, :production
set :server_type, 'production'

set :deploy_to, "/u/apps/etengine"
set :db_host, "etm.cr6sxqj0itls.eu-west-1.rds.amazonaws.com"

task :production do
  set :domain, "et-engine.com"
  set :branch, "production"
  set :db_pass, "HaLjXwRWmu60DK"
  set :db_name, application_key
  set :db_user, application_key
  set :airbrake_key, "c7aceee5954aea78f93e7ca4b22439c7"
  server domain, :web, :app, :db, :primary => true
end

task :beta do
  staging
end

task :staging do
  set :domain, "beta.et-engine.com"
  set :branch, "staging"
  set :db_pass, "r8ZPP7pQTDTBha"
  set :db_name, 'etengine_staging'
  set :db_user, 'etengine_staging'
  set :airbrake_key, "e483e275c8425821ec21580e0ffefe9d"
  server domain, :web, :app, :db, :primary => true
end

task :edge do
  # set :domain, "edge.et-engine.com"
  set :domain, "ec2-176-34-77-157.eu-west-1.compute.amazonaws.com"
  set :branch, "edge"
  set :db_pass, "lVtSsSv43KooQE"
  set :db_name, "etengine_edge"
  set :db_user, "etengine_edge"
  set :airbrake_key, "e483e275c8425821ec21580e0ffefe9d"
  server domain, :web, :app, :db, :primary => true
end

set :user, 'ubuntu'
set :scm, :git
set :repository, "git@github.com:dennisschoenmakers/etengine.git"
set :deploy_via, :remote_cache
set :chmod755, "app config db lib public vendor script script/* public/disp*"  	# Some files that will need proper permissions set :use_sudo, false
ssh_options[:forward_agent] = true
set :use_sudo, false
set :local_db_name, 'etengine_dev'
set :bundle_flags, '--deployment --quiet --binstubs --shebang ruby-local-exec'

