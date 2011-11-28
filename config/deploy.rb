require 'bundler/capistrano'

set :application, "etengine"
set :stage, :production
set :server_type, 'production'

task :production do
  set :domain, "et-engine.com"
  set :branch, "production"

  set :application_key, "#{application}"
  set :deploy_to, "/home/ubuntu/apps/#{application_key}"
  set :config_files, "/home/ubuntu/config_files/#{application_key}"
  
  set :db_host, "etm.cr6sxqj0itls.eu-west-1.rds.amazonaws.com"
  set :db_pass, "Energy2.0"
  set :db_name, application_key
  set :db_user, application_key

  set :airbrake_key, "c7aceee5954aea78f93e7ca4b22439c7"

  role :web, domain # Your HTTP server, Apache/etc
  role :app, domain # This may be the same as your `Web` server
  role :db,  domain, :primary => true # This is where Rails migrations will run
  
end

task :staging do
  set :domain, "beta.et-engine.com"
  set :branch, "staging"

  # change this to #{application}_staging when you want it in a different directory
  set :application_key, "#{application}_staging" 
  set :deploy_to, "/home/ubuntu/apps/#{application_key}"
  set :config_files, "/home/ubuntu/config_files/#{application_key}"

  set :db_host, "etm.cr6sxqj0itls.eu-west-1.rds.amazonaws.com"
  set :db_pass, "r8ZPP7pQTDTBha"
  set :db_name, application_key
  set :db_user, application_key

  set :airbrake_key, "e483e275c8425821ec21580e0ffefe9d"

  role :web, domain # Your HTTP server, Apache/etc
  role :app, domain # This may be the same as your `Web` server
  role :db,  domain, :primary => true # This is where Rails migrations will run
end


task :release do
  set :domain, "ec2-46-137-63-176.eu-west-1.compute.amazonaws.com"
  set :branch, "release"

  set :application_key, "#{application}_rc"
  set :deploy_to, "/home/ubuntu/apps/#{application}"  ## this is a copy of production, so serverconfig stays the same
  set :config_files, "/home/ubuntu/config_files/#{application}" ## this is a copy of production, so serverconfig stays the same

  set :db_host, "etm.cr6sxqj0itls.eu-west-1.rds.amazonaws.com"
  set :db_pass, "quintel"
  set :db_name, application_key
  set :db_user, 'root'

  set :airbrake_key, "c0323ccf9d5e2ac0b00772d0f4fb93c9"

  role :web, domain # Your HTTP server, Apache/etc
  role :app, domain # This may be the same as your `Web` server
  role :db,  domain, :primary => true # This is where Rails migrations will run
end 

set :user, 'ubuntu'

set :scm, :git
set :repository,  "git@github.com:dennisschoenmakers/etengine.git"
set :deploy_via, :remote_cache
set :chmod755, "app config db lib public vendor script script/* public/disp*"  	# Some files that will need proper permissions set :use_sudo, false
ssh_options[:forward_agent] = true
set :use_sudo,     false
set :rvm_ruby_string, '1.9.2'

set :local_db_name, 'etengine_dev'
