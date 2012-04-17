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
    # Symlink to dynamically generated rdocs if they exist.
    # Regenerate docs manually With: cap ... deploy:doc
    run "if [ -d #{shared_path}/doc ]; then ln -s #{shared_path}/doc #{release_path}/public/; fi"

    memcached.flush
  end

  task :wipe_cache do
    memcached.restart
    restart
  end

  desc 'Manually regenerate documentation'
  task :doc do
    doc_path = "#{shared_path}/doc"
    # create shared/doc if not exists already and symlink to public/doc
    run "if [ ! -d #{doc_path} ]; then mkdir #{doc_path}; fi"
    run "ln -sf #{shared_path}/doc #{current_path}/public/"
    run "cd #{current_path}; rake yard"
  end
end

after "deploy:update_code", "deploy:copy_configuration_files"
after "deploy", "deploy:cleanup"
