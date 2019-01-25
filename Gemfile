ruby '2.4.2'

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{ repo_name }/#{ repo_name }" unless repo_name.include?('/')
  "https://github.com/#{ repo_name }.git"
end

gem 'bootsnap', require: false

gem 'rails',        '~> 5.1.6'
gem 'jquery-rails', '~> 4.0'
gem 'haml',         '~> 5.0'
gem 'json',         '~> 1.8.1'

# https://stackoverflow.com/questions/35893584/nomethoderror-undefined-method-last-comment-after-upgrading-to-rake-11
gem 'rake', '< 11.0'

gem 'gravatar_image_tag'

# Ruby gems
gem 'ruby_deep_clone', '~> 0.8', require: 'deep_clone'
gem 'ice_nine'
gem 'distribution', '~> 0.6'
gem 'text-table'
gem 'osmosis',                github: 'quintel/osmosis'

# Rails gem
gem 'simple_form'
gem 'devise', '~> 4.0'
gem 'cancancan', '~> 2.0'
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
gem 'parallel'

# own gems
gem 'rubel',         ref: 'e36554a',  github: 'quintel/rubel'
gem 'quintel_merit', ref: '0f33926',  github: 'quintel/merit'
gem 'fever',         ref: 'f80677d',  github: 'quintel/fever'
gem 'turbine-graph', '>=0.1',         require: 'turbine'
gem 'refinery',      ref: '253158c',  github: 'quintel/refinery'
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
gem 'atlas',         ref: 'dcc7d55',  github: 'quintel/atlas'
=======
gem 'atlas',         ref: 'c41054c',  github: 'quintel/atlas'
>>>>>>> Add support for ETSource config files
=======
gem 'atlas',         ref: '1cc5ae3',  github: 'quintel/atlas'
>>>>>>> Support new type/subtype Merit attributes
=======
gem 'atlas',         ref: 'c03baed',  github: 'quintel/atlas'
>>>>>>> Updated atlas

# system gems
gem 'mysql2'
gem 'dalli'

gem 'term-ansicolor', '1.0.7', require: false
gem 'highline',                require: false

gem 'sentry-raven'

group :development do
  gem 'spring'
  # gem 'quiet_assets'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'listen'

  gem 'capistrano',             '~> 3.9',   require: false
  gem 'capistrano-rbenv',       '~> 2.1',   require: false
  gem 'capistrano-rails',       '~> 1.1',   require: false
  gem 'capistrano-bundler',     '~> 1.1',   require: false
  gem 'capistrano3-puma',       '~> 3.1.1', require: false
end

group :test, :development do
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rspec-rails', '~> 3.7'
  gem 'watchr'
end

group :test do
  gem 'factory_bot_rails'
  gem 'rails-controller-testing'
  gem 'shoulda-matchers'

  gem 'simplecov', '~> 0.7.1', require: false
end

group :production, :staging do
  gem 'puma'
  gem 'gctools', require: false
  gem 'newrelic_rpm'
end
