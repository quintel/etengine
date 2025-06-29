ruby '~> 3.2.7'

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{ repo_name }/#{ repo_name }" unless repo_name.include?('/')
  "https://github.com/#{ repo_name }.git"
end

gem 'bootsnap', require: false
gem 'puma'

gem 'rails',        '~> 7.1.5'
gem 'jquery-rails', '~> 4.0'
gem 'haml'
gem 'json'

gem 'rake'
gem 'activeresource', '~> 6.0'

# Ruby gems
gem 'ice_nine'
gem 'text-table'
gem 'osmosis',                github: 'quintel/osmosis'

# gem 'numo-narray', require: 'numo/narray'

# Rails gem
gem 'simple_form'
gem 'ruby-graphviz',                  require: 'graphviz'
gem 'rack-cors',                      require: 'rack/cors'
gem 'kaminari'

# Authentication and authorization
gem 'cancancan', '~> 3.0'
gem 'identity', ref: 'e18aa91', github: 'quintel/identity_rails'

gem 'activerecord-session_store'
gem 'sidekiq'

# Auth front-end
gem 'dry-initializer'
gem 'dry-monads'
gem 'dry-struct'
gem 'dry-validation'

gem 'jbuilder'
gem 'erb-formatter'
gem 'http_accept_language'
gem 'importmap-rails'
gem 'inline_svg'
gem 'letter_opener'
gem 'local_time'
gem 'stimulus-rails'
gem 'tailwindcss-rails'
gem 'turbo-rails'
gem 'view_component'

# gem 'sass-rails'
gem 'sprockets-rails'
gem 'mini_racer'
gem 'coffee-rails'

# gem 'dotenv-rails', groups: [:development, :test, :production, :staging]
gem 'config'

# API
gem 'rest-client'

# for etsource
gem 'git', '~> 1.19'
gem 'fnv'
gem 'parallel'
gem 'ruby-progressbar'

# own gems
gem 'quintel_merit', ref: '54d2be1', github: 'quintel/merit'
gem 'atlas',         ref: '8e854b1', github: 'quintel/atlas'
gem 'fever',         ref: '2a91194', github: 'quintel/fever'
gem 'refinery',      ref: 'c39c9b1', github: 'quintel/refinery'
gem 'rubel',         ref: 'e36554a', github: 'quintel/rubel'
gem 'turbine-graph', '>=0.1',        require: 'turbine'

# system gems
gem 'mysql2'
gem 'dalli'

gem 'term-ansicolor', '1.0.7', require: false
gem 'highline',                require: false

# sentry gems
gem "stackprof"
gem 'sentry-ruby'
gem "sentry-rails"
gem "sentry-sidekiq"

group :development do
  # gem 'quiet_assets'
  gem 'better_errors'
  gem 'listen'
end

group :test, :development do
  gem 'binding_of_caller'
  gem 'factory_bot_rails'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rspec-rails', '~> 7.0'
  gem 'watchr'

  gem 'rubocop',             '~> 1.27', require: false
  gem 'rubocop-performance',            require: false
  gem 'rubocop-rails',                  require: false
  gem 'rubocop-rspec',                  require: false
end

group :test do
  gem 'rails-controller-testing'
  gem 'shoulda-matchers'

  # System tests
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'webdrivers'

  gem 'simplecov', '~> 0.7.1', require: false
end

group :production, :staging do
  # gem 'gctools', require: false
  gem 'newrelic_rpm'
end
