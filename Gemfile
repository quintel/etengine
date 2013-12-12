source 'http://rubygems.org'
source 'http://gems.github.com'

gem 'rails',        '~> 4.0.2'
gem 'jquery-rails', '~> 2.0.2'
gem 'haml',         '~> 4.0'
gem 'json',         '~> 1.8.1'

gem 'gravatar_image_tag'

# Ruby gems
gem 'deep_clone',             github: 'quintel/ruby-deepclone'
gem 'distribution', '~> 0.6'
gem 'text-table'
gem 'osmosis',                github: 'quintel/osmosis'

# Rails gem
gem 'simple_form'
gem 'devise'
gem 'cancan'
gem 'ruby-graphviz',                  require: 'graphviz'
gem 'rack-cors',                      require: 'rack/cors'
gem 'default_value_for'
gem 'kaminari'

# API
gem 'rest-client'

# for etsource
gem 'git',                            git: 'git://github.com/bradhe/ruby-git.git'
gem 'activerecord-import'
gem 'fnv'
gem 'ruby-progressbar'
gem 'msgpack'

# own gems
gem 'rubel',         '>= 0.0.3',       github:  'quintel/rubel'
gem 'merit',         '>=0.1.0',        git:     'git@github.com:quintel/merit.git'
gem 'turbine-graph', '>=0.1',          require: 'turbine'
gem 'refinery',      ref: 'a0dcae9',   git:     'git@github.com:quintel/refinery.git'
gem 'atlas',         ref: '59df5f7',   git:     'git@github.com:quintel/atlas.git'

# system gems
gem 'mysql2',         '~>0.3.11'
gem 'dalli'
gem 'term-ansicolor', '1.0.7',    require: false
gem 'highline',                   require: false
gem 'rubyzip',        '0.9.4'
gem 'fileutils'

# documentation gems. Needed on production too for dynamically generated docs.
group :development, :production do
  gem 'yard',      '~> 0.7.2'
  gem 'rdiscount'
end

group :development do
  gem 'annotate'
  gem 'ruby-prof'
  gem 'quiet_assets'
  gem 'better_errors'
  gem 'listen'

  gem 'capistrano',         require: false
  gem 'capistrano-unicorn', require: false
end

group :test, :development do
  gem 'rspec-rails', '~> 2.12'
  gem 'ruby-prof'
  gem 'pry-rails'
  gem 'pry-remote'
  gem 'pry-stack_explorer'
  gem 'pry-debugger'
  gem 'guard'
  gem 'guard-rspec'
  gem 'watchr'
end

group :test do
  gem 'factory_girl_rails'
  gem 'shoulda-matchers'
  gem 'simplecov', '~> 0.7.1', require: false
end

group :darwin do
  gem 'rb-fsevent'
end

group :production do
  gem 'unicorn'
  gem 'airbrake'
end

group :assets do
  gem 'sass-rails'
  gem 'therubyracer', '>= 0.12.0'
  gem 'libv8',        '>= 3.16.14.3'
  gem 'coffee-rails'
end
