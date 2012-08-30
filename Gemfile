source 'http://rubygems.org'
source 'http://gems.github.com'

gem 'rails', '3.2.7'
gem 'jquery-rails', '~> 2.0.2'
gem 'haml', '~>3.1.4'

gem 'authlogic'
gem 'cancan'
gem 'simple_form'
gem 'ruby-graphviz', :require => "graphviz"
gem 'default_value_for'
gem 'kaminari', "~> 0.13.0"
gem 'distribution', '~> 0.6' # This gem is only used for GQL: NORMCDF()
gem 'text-table'
gem 'jbuilder', :git => 'git://github.com/rails/jbuilder.git'

gem 'rest-client'

# pry is needed in production for the gql:console
gem 'pry', '~> 0.9.9.3'

# for etsource
gem 'git', :git => 'git://github.com/bradhe/ruby-git.git'
gem 'activerecord-import', '~> 0.2.9'
gem 'fnv'

# own gems
gem "yaml_pack", '~>0.0.3.alpha'
gem 'rubel', '0.0.3'

gem 'rack-cors', :require => 'rack/cors'
gem 'airbrake'
gem 'hipchat'

# system gems
gem 'mysql2', '~>0.3.11'
gem 'dalli'
gem 'term-ansicolor', :require => false
gem 'highline', :require => false
gem 'rubyzip', '0.9.4'
gem 'fileutils'

# documentation gems. Needed on production too for dynamically generated docs.
group :development, :production do
  gem 'yard', '~> 0.7.2'
  # tomdoc to buggy right now
  # gem 'yard-tomdoc'
  gem 'rdiscount'
end

group :development do
  gem 'annotate', :require => false
  gem 'ruby-prof'

  # ETsource live-reloading.
  gem 'listen'
end

group :test, :development do
  gem "rspec-rails", "~> 2.11.0"
  gem 'ruby-prof'
  gem 'pry-rails'
  gem 'pry-remote'
  gem 'pry-stack_explorer'
  gem 'pry-debugger'
  gem 'guard'
  gem 'guard-rspec'
  gem 'spork', '~> 0.9.0.rc'
  gem 'guard-spork'
  gem 'watchr'
end

group :test do
  gem 'factory_girl_rails'
  gem 'shoulda-matchers'
  gem 'webrat'
  gem 'simplecov', '~> 0.5.3', :require => false
end

group :darwin do
  gem 'rb-fsevent'
end

group :production do
  gem 'unicorn'
end

group :assets do
  gem 'sass-rails', '~>3.2.3'
end
