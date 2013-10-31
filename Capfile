require 'bundler/capistrano'
require 'airbrake/capistrano'
require 'capistrano-unicorn'

load 'deploy'

load 'lib/capistrano/db_recipes'
load 'lib/capistrano/memcached'
load 'lib/capistrano/deploy'
load 'deploy/assets'

load 'config/deploy'

after 'bundle:install',     'deploy:app_config'  # Config and ETSource.
after 'deploy:update_code', 'deploy:etsource'
after 'deploy:restart',     'unicorn:restart'    # Reload Unicorn.
after 'deploy:restart',     'memcached:flush'    # Clear caches.
after 'deploy',             'deploy:cleanup'
