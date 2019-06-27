lock '3.10.1'

set :log_level, 'info'
set :pty, true

set :application, 'etengine'
set :repo_url, 'https://github.com/quintel/etengine.git'

# Set up rbenv
set :rbenv_type, :user
set :rbenv_ruby, '2.4.2'
set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
set :rbenv_map_bins, %w[rake gem bundle ruby rails]

set :bundle_binstubs, -> { shared_path.join('sbin') }

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
# set :deploy_to, "/var/www/#{fetch(:application)}"

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w[
  .env
  config/.etsource_password
  config/database.yml
  config/email.yml
  config/newrelic.yml
]

# Default value for linked_dirs is []
set :linked_dirs, %w[
  log
  public/system
  sbin
  tmp/cache
  tmp/pids
  tmp/sockets
  vendor/bundle
]

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do
  after  'bundler:install',   'deploy:app_config'
  before 'deploy:publishing', 'deploy:etsource'

  after :publishing, :restart

  after :restart, :clear_cache do
    invoke 'memcached:flush'
  end
end
