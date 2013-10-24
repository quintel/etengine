require 'bundler/capistrano'
require 'airbrake/capistrano'
require 'capistrano-unicorn'

load 'deploy' if respond_to?(:namespace) # cap2 differentiator
load 'lib/capistrano/db_recipes'
load 'lib/capistrano/memcached'
load 'deploy/assets'

load 'config/deploy' # remove this line to skip loading any of the default tasks

namespace :deploy do
  task :symlink_configuration_files do
    run "ln -sf #{shared_path}/config/config.yml #{release_path}/config/"
    run "ln -sf #{shared_path}/config/database.yml #{release_path}/config/"
    run "ln -sf #{shared_path}/config/latest_etsource_import_sha #{release_path}/config/"
    run "cd #{release_path}; chmod 777 tmp"
    run "ln -nfs #{shared_path}/vendor_bundle #{release_path}/vendor/bundle"
    # Symlink to dynamically generated rdocs if they exist.
    # Regenerate docs manually With: cap ... deploy:doc
    run "if [ -d #{shared_path}/doc ]; then ln -sf #{shared_path}/doc #{release_path}/public/; fi"

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

  desc 'Calculates the datasets from ETSource using Atlas and Refinery'
  task :calculate_datasets do
    run "cd #{release_path}; RAILS_ENV=#{rails_env} rake calculate_datasets"
  end
end

# before_fork hook implemented (zero downtime deployments)
after 'deploy:restart', 'unicorn:duplicate'

after "deploy:update_code", "deploy:symlink_configuration_files"
after "deploy:update_code", "deploy:calculate_datasets"
after "deploy", "deploy:cleanup"
before 'deploy:assets:precompile', "deploy:symlink_configuration_files"
