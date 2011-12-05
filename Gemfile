source 'http://rubygems.org'
source 'http://gems.github.com'

gem 'rails', '3.0.11'
gem 'jquery-rails', '~> 1.0.14'
gem 'haml', '~>3.1.3'
gem 'sass', '~>3.1.7'

gem 'authlogic'
gem 'cancan'
gem 'simple_form'
gem 'paper_trail', '>= 1.6.4'
gem 'ruby-graphviz', :require => "graphviz"
gem 'treetop', '1.4.8'
gem 'default_value_for'
gem 'tabs_on_rails'
gem 'kaminari'
gem 'distribution', '~> 0.6' # This gem is only used for GQL: NORMCDF()

# for etsource
gem 'git', :git => 'git://github.com/bradhe/ruby-git.git'
gem 'activerecord-import'
gem 'fnv'

# javascript
gem 'sprockets'
gem 'sprockets-rails'
gem 'rack-sprockets'

# supporting gems
gem 'airbrake', '3.0.4'

# system gems
# gem 'thinking-sphinx', '>=2.0.1'
gem 'mysql2', '~>0.2.6'
gem 'dalli'
gem 'memcache-client'
gem 'term-ansicolor', :require => false
gem 'highline', :require => false

gem 'rubyzip', '0.9.4'
gem 'fileutils'

group :development do
  gem 'yard', '~> 0.7.2'
  gem 'annotate', :require => false
  gem 'active_reload'
end

group :test, :development do
  gem "rspec-rails", "~> 2.7.0"
  gem 'ruby-prof'
  gem 'pry'
  gem 'guard'
  gem 'guard-rspec'
end

group :test do
  gem 'factory_girl_rails', "~> 1.2.0"
  gem 'shoulda-matchers'
  gem 'webrat'
  gem 'simplecov', '~> 0.5.3', :require => false
  gem 'spork', '~> 0.9.0.rc'
  gem 'guard-spork'
end

group :darwin do
  gem 'rb-fsevent'
end