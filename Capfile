require 'bundler/capistrano'

load 'deploy' if respond_to?(:namespace) # cap2 differentiator
load 'lib/capistrano/db_recipes'

load 'config/deploy' # remove this line to skip loading any of the default tasks

namespace :memcached do
  desc "Start memcached"
  task :start, :roles => [:app] do
    sudo "/etc/init.d/memcached start"
  end

  desc "Stop memcached"
  task :stop, :roles => [:app] do
    sudo "/etc/init.d/memcached stop"
  end

  desc "Restart memcached"
  task :restart, :roles => [:app] do
    sudo "/etc/init.d/memcached restart"
  end

  desc "Flush memcached - this assumes memcached is on port 11211"
  task :flush, :roles => [:app] do
    sudo "echo 'flush_all' | nc -q 1 localhost 11211"
  end
end


namespace :deploy do
  task :copy_configuration_files do
    run "ln -s #{shared_path}/config/config.yml #{release_path}/config/"
    run "ln -s #{shared_path}/config/database.yml #{release_path}/config/"
    run "ln -s #{shared_path}/config/latest_etsource_import_sha #{release_path}/config/"
    run "cd #{release_path}; chmod 777 public/images public/stylesheets tmp"
    run "ln -nfs #{shared_path}/vendor_bundle #{release_path}/vendor/bundle"
    memcached.flush
  end

  task :symlink_etsource do
    # raise "etsource does not exist. check out github branch etsource into /home/ubuntu" unless remote_dir_exists?("/home/ubuntu/etsource")
    run "ln -s /home/ubuntu/etsource #{release_path}/etsource"
  end

  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  task :wipe_cache do
    memcached.restart
    restart
  end

  desc "Notify Airbrake of the deployment"
  task :notify_airbrake, :except => { :no_release => true } do
    rails_env = fetch(:hoptoad_env, fetch(:rails_env, "production"))
    local_user = ENV['USER'] || ENV['USERNAME']
    notify_command = "bundle exec rake airbrake:deploy TO=#{rails_env} REVISION=#{current_revision} REPO=#{repository} USER=#{local_user} API_KEY=#{airbrake_key}"
    puts "Notifying Airbrake of Deploy of #{server_type} (#{notify_command})"
    run "cd #{release_path} && #{notify_command}"
    puts "Airbrake Notification Complete."
  end
end

after "deploy:update_code", "deploy:copy_configuration_files"
after "deploy:update_code", "deploy:symlink_etsource"
after "deploy", "deploy:notify_airbrake"
after "deploy", "deploy:cleanup"
