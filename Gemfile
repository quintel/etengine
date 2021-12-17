ruby '2.7.4'

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{ repo_name }/#{ repo_name }" unless repo_name.include?('/')
  "https://github.com/#{ repo_name }.git"
end

gem 'bootsnap', require: false

gem 'rails',        '~> 5.2.6'
gem 'jquery-rails', '~> 4.0'
gem 'haml',         '~> 5.0'
gem 'json'

gem 'rake'

gem 'gravatar_image_tag'

# Ruby gems
gem 'ruby_deep_clone', '~> 0.8', require: 'deep_clone'
gem 'ice_nine'
gem 'distribution', '~> 0.6'
gem 'text-table'
gem 'osmosis',                github: 'quintel/osmosis'

gem 'numo-narray', require: 'numo/narray'

# Rails gem
gem 'simple_form'
gem 'devise', '~> 4.7'
gem 'cancancan', '~> 2.0'
gem 'ruby-graphviz',                  require: 'graphviz'
gem 'rack-cors',                      require: 'rack/cors'
gem 'kaminari'

gem 'sass-rails'
gem 'mini_racer', '>= 0.4.0.beta1'
gem 'coffee-rails'

gem 'dotenv-rails', groups: [:development, :test, :production, :staging]

# API
gem 'rest-client'

# for etsource
gem 'git',                            github: 'bradhe/ruby-git'
gem 'fnv'
gem 'msgpack'
gem 'parallel'
gem 'ruby-progressbar'

# own gems
gem 'quintel_merit', ref: '1441cfd', github: 'quintel/merit'

gem 'atlas',         ref: 'dd2f88c', github: 'quintel/atlas'
gem 'fever',         ref: 'f80677d', github: 'quintel/fever'
gem 'refinery',      ref: '72eacf8', github: 'quintel/refinery'
gem 'rubel',         ref: 'e36554a', github: 'quintel/rubel'
gem 'turbine-graph', '>=0.1',        require: 'turbine'

# system gems
gem 'mysql2'
gem 'dalli'
gem 'gpgme'

gem 'term-ansicolor', '1.0.7', require: false
gem 'highline',                require: false

gem 'sentry-raven'

group :development do
  gem 'spring'
  # gem 'quiet_assets'
  gem 'better_errors'
  gem 'listen'

  gem 'capistrano',             '~> 3.9',   require: false
  gem 'capistrano-rbenv',       '~> 2.1',   require: false
  gem 'capistrano-rails',       '~> 1.6',   require: false
  gem 'capistrano-bundler',     '~> 1.1',   require: false
  gem 'capistrano3-puma',       '~> 5.0.4', require: false
end

group :test, :development do
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rspec-rails', '~> 5.0'
  gem 'watchr'
  gem 'binding_of_caller'

  gem 'rubocop',             '~> 0.85.0', require: false
  gem 'rubocop-performance',              require: false
  gem 'rubocop-rails',                    require: false
  gem 'rubocop-rspec',                    require: false
end

group :test do
  gem 'factory_bot_rails'
  gem 'rails-controller-testing'
  gem 'shoulda-matchers'

  gem 'simplecov', '~> 0.7.1', require: false
end

group :production, :staging do
  gem 'puma', '< 5'
  gem 'gctools', require: false
  gem 'newrelic_rpm'
end
