source 'http://rubygems.org'
source 'http://gems.github.com'

gem 'rails', '3.2.3'
gem 'jquery-rails', '~> 1.0.19'
gem 'haml', '~>3.1.4'

gem 'authlogic'
gem 'cancan'
gem 'simple_form'
gem 'ruby-graphviz', :require => "graphviz"
gem 'treetop', '1.4.8'
gem 'default_value_for'
gem 'tabs_on_rails'
gem 'kaminari'
gem 'distribution', '~> 0.6' # This gem is only used for GQL: NORMCDF()
gem 'text-table'
gem 'jbuilder', :git => 'git://github.com/rails/jbuilder.git'

# for etsource
gem 'git', :git => 'git://github.com/bradhe/ruby-git.git'
gem 'activerecord-import', '~> 0.2.9'
gem 'fnv'
gem "yaml_pack", '~>0.0.3.alpha'

gem 'rack-cors', :require => 'rack/cors'
gem 'airbrake'

# system gems
gem 'mysql2', '~>0.3.11'
gem 'dalli'
gem 'memcache-client'
gem 'term-ansicolor', :require => false
gem 'highline', :require => false
gem 'rubyzip', '0.9.4'
gem 'fileutils'

# documentation gems. Needed on production too for dynamically generated docs.
group :development, :production do
  gem 'yard', '~> 0.7.2'
  gem 'yard-tomdoc'
  gem 'rdiscount'
end

group :development do
  gem 'annotate', :require => false
  gem 'active_reload'
  gem 'pry-remote'
  gem 'ruby-prof'
end

group :test, :development do
  gem "rspec-rails", "~> 2.8.0"
  gem 'ruby-prof'
  gem 'pry'
  gem 'guard'
  gem 'guard-rspec'
  gem 'spork', '~> 0.9.0.rc'
  gem 'guard-spork'
end

group :test do
  gem 'factory_girl_rails', "~> 1.2.0"
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
