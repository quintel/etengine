require 'bundler/capistrano'
require 'hoptoad_notifier/capistrano'

set :application, "etengine"
set :stage, :production
set :server_type, 'production'

task :production do
  set :domain, "46.137.90.62"
  set :branch, "production"

  set :application_key, "#{application}"
  set :deploy_to, "/home/ubuntu/apps/#{application_key}"
  set :config_files, "/home/ubuntu/config_files/#{application_key}"

  role :web, domain # Your HTTP server, Apache/etc
  role :app, domain # This may be the same as your `Web` server
  role :db,  domain, :primary => true # This is where Rails migrations will run
end

task :staging do
  set :domain, "ec2-46-137-12-48.eu-west-1.compute.amazonaws.com"
  set :branch, "staging"

  # change this to #{application}_staging when you want it in a different directory
  set :application_key, "#{application}_staging" 
  set :deploy_to, "/home/ubuntu/apps/#{application_key}"
  set :config_files, "/home/ubuntu/config_files/#{application_key}"

  role :web, domain # Your HTTP server, Apache/etc
  role :app, domain # This may be the same as your `Web` server
  role :db,  domain, :primary => true # This is where Rails migrations will run
end


set :user, 'ubuntu'

set :scm, :git
set :repository,  "git@github.com:dennisschoenmakers/etengine.git"
set :scm, "git"
set :deploy_via, :remote_cache
set :chmod755, "app config db lib public vendor script script/* public/disp*"  	# Some files that will need proper permissions set :use_sudo, false
ssh_options[:forward_agent] = true
set :use_sudo,     false
set :rvm_ruby_string, '1.9.2'
