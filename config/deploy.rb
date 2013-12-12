# require 'dotenv'
# Dotenv.load

set :application, "etengine"
set :application_key, "etengine"
set :stage, :production
set :server_type, 'production'

set :deploy_to, "/u/apps/etengine"

set(:unicorn_bin) { "#{current_path}/bin/unicorn" }
set(:unicorn_pid) { "#{current_path}/tmp/pids/unicorn.pid" }

# Reads and returns the contents of a remote +path+, caching it in case of
# multiple calls.
def remote_file(path)
  @remote_files ||= {}
  @remote_files[path] ||= capture("cat #{ path }")
end

# Reads the remote .env file to set the Airbrake key locally in Capistrano.
def fetch_remote_airbrake_key
  key = remote_file("#{shared_path}/.env").match(/^AIRBRAKE_API_KEY=(.+)$/)
  key && key[1]
end

# Reads the remote database.yml file to read the value of an attribute. If a
# matching environment variable is set (prefixed with "DB_"), it will be used
# instead.
def remote_db_config(key)
  ENV["DB_#{ key.to_s.upcase }"] ||
    YAML.load(
      remote_file("#{shared_path}/config/database.yml")
    )[stage.to_s][key.to_s]
end

task :production do
  set :domain, "et-engine.com"
  set :branch, fetch(:branch, "production")

  server domain, :web, :app, :db, :primary => true

  set :db_host, remote_db_config(:host) || '127.0.0.1'
  set :db_pass, remote_db_config(:password)
  set :db_name, remote_db_config(:database)
  set :db_user, remote_db_config(:username)

  set :airbrake_key, fetch_remote_airbrake_key
end

task :staging do
  set :domain, "beta.et-engine.com"
  set :branch, fetch(:branch, "staging")

  server domain, :web, :app, :db, :primary => true

  set :db_host, remote_db_config(:host) || '127.0.0.1'
  set :db_pass, remote_db_config(:password)
  set :db_name, remote_db_config(:database)
  set :db_user, remote_db_config(:username)

  set :airbrake_key, fetch_remote_airbrake_key
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
