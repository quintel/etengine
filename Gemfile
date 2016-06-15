source 'http://rubygems.org'
source 'http://gems.github.com'

gem 'rails',        '~> 4.1.0'
gem 'jquery-rails', '~> 2.0.2'
gem 'haml',         '~> 4.0'
gem 'json',         '~> 1.8.1'

gem 'gravatar_image_tag'

# Ruby gems
gem 'ruby_deep_clone',        github: 'balmma/ruby-deepclone', require: 'deep_clone'
gem 'distribution', '~> 0.6'
gem 'text-table'
gem 'osmosis',                github: 'quintel/osmosis'

# Rails gem
gem 'simple_form'
gem 'devise'
gem 'cancan'
gem 'ruby-graphviz',                  require: 'graphviz'
gem 'rack-cors',                      require: 'rack/cors'
gem 'kaminari'

gem 'sass-rails'
gem 'therubyracer', '>= 0.12.0'
gem 'coffee-rails'

gem 'dotenv-rails', groups: [:development, :test, :production, :staging]

# API
gem 'rest-client'

# for etsource
gem 'git',                            github: 'bradhe/ruby-git'
gem 'fnv'
gem 'msgpack'

# own gems
gem 'rubel',         ref: 'e36554a',   github:  'quintel/rubel'
gem 'quintel_merit', ref: '20d7294',   github:  'quintel/merit'
gem 'turbine-graph', '>=0.1',          require: 'turbine'
gem 'refinery',      ref: '58c1138',   github: 'quintel/refinery'
gem 'atlas',         ref: '5077e56',   github: 'quintel/atlas'

# system gems
gem 'mysql2',         '~>0.3.11'
gem 'dalli'

gem 'term-ansicolor', '1.0.7', require: false
gem 'highline',                require: false

group :development do
  gem 'spring'
  gem 'quiet_assets'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'listen'

  gem 'capistrano',             '~> 3.0',   require: false
  gem 'capistrano-rbenv',       '~> 2.0',   require: false
  gem 'capistrano-rails',       '~> 1.1',   require: false
  gem 'capistrano-bundler',     '~> 1.1',   require: false
  gem 'capistrano3-unicorn',    '~> 0.2',   require: false
end

group :test, :development do
  gem 'rspec-rails', '~> 2.12'
  gem 'pry-rails'
  gem 'guard'
  gem 'guard-rspec'
  gem 'watchr'

  gem 'pry-byebug', platforms: [:mri_20, :mri_21]
end

group :test do
  gem 'factory_girl_rails'
  gem 'shoulda-matchers',      require: false
  gem 'simplecov', '~> 0.7.1', require: false
end

group :production, :staging do
  gem 'unicorn'
  gem 'gctools', require: false
  gem 'airbrake'
  gem 'newrelic_rpm'
end
