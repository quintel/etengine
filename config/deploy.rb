# require 'dotenv'
# Dotenv.load

set :application, "etengine"
set :application_key, "etengine"
set :stage, :production
set :server_type, 'production'

set :deploy_to, "/u/apps/etengine"

set(:unicorn_bin) { "#{current_path}/bin/unicorn" }
set(:unicorn_pid) { "#{current_path}/tmp/pids/unicorn.pid" }

# Reads the remote .env file to set the Airbrake key locally in Capistrano.
def fetch_remote_airbrake_key
  @airbrake_api_key ||= begin
    key = capture("cat #{shared_path}/.env").match(/^AIRBRAKE_API_KEY=(.+)$/)
    key && key[1]
  end
end

task :production do
  set :domain, "et-engine.com"
  set :branch, fetch(:branch, "production")
  set :db_pass, "1TObSSWD54mmRj5fJTj6"
  set :db_host, "127.0.0.1"
  set :db_name, "etengine"
  set :db_user, "root"

  server domain, :web, :app, :db, :primary => true

  set :airbrake_key, fetch_remote_airbrake_key
end

task :staging do
  set :domain, "beta.et-engine.com"
  set :branch, fetch(:branch, "staging")
  set :db_pass, "Ce9pQnEDjMQZ139z_ldV"
  set :db_host, "127.0.0.1"
  set :db_name, 'etengine_staging'
  set :db_user, "root"

  server domain, :web, :app, :db, :primary => true

  set :airbrake_key, fetch_remote_airbrake_key
end

task :show do
  puts domain
  puts airbrake_key
end

set :user, 'ubuntu'
set :scm, :git
set :repository, "git@github.com:quintel/etengine.git"
set :deploy_via, :remote_cache
set :chmod755, "app config db lib public vendor script script/* public/disp*"  	# Some files that will need proper permissions set :use_sudo, false
ssh_options[:forward_agent] = true
set :use_sudo, false
set :local_db_name, 'etengine_dev'
set :bundle_flags, '--deployment --quiet --binstubs --shebang ruby-local-exec'
