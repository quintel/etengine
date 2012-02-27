require 'bundler/capistrano'
require 'airbrake/capistrano'

load 'deploy' if respond_to?(:namespace) # cap2 differentiator
load 'lib/capistrano/db_recipes'
load 'lib/capistrano/memcached'
load 'lib/capistrano/unicorn'

load 'config/deploy' # remove this line to skip loading any of the default tasks

namespace :deploy do
  task :copy_configuration_files do
    run "ln -s #{shared_path}/config/config.yml #{release_path}/config/"
    run "ln -s #{shared_path}/config/database.yml #{release_path}/config/"
    run "ln -s #{shared_path}/config/latest_etsource_import_sha #{release_path}/config/"
    run "ln -s #{shared_path}/config/latest_etsource_export_sha #{release_path}/config/"
    run "cd #{release_path}; chmod 777 public/images public/stylesheets tmp"
    run "ln -nfs #{shared_path}/vendor_bundle #{release_path}/vendor/bundle"
    memcached.flush
  end

  task :symlink_etsource do
    # raise "etsource does not exist. check out github branch etsource into /home/ubuntu" unless remote_dir_exists?("/home/ubuntu/etsource")
    run "ln -s /home/ubuntu/etsource #{release_path}/etsource"
  end

  task :wipe_cache do
    memcached.restart
    restart
  end
end

after "deploy:update_code", "deploy:copy_configuration_files"
after "deploy:update_code", "deploy:symlink_etsource"
after "deploy", "deploy:cleanup"
