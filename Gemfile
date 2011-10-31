source 'http://rubygems.org'
source 'http://gems.github.com'

gem 'rails', '3.0.10'
gem 'jquery-rails', '~> 1.0.14'
gem 'haml', '~>3.1.3'
gem 'sass', '~>3.1.7'
gem 'rake', '0.9.2' # 0.9 breaks things

gem 'authlogic'
gem 'simple_form'
gem 'paper_trail', '>= 1.6.4'
gem 'ruby-graphviz', :require => "graphviz"
gem 'treetop', '1.4.8'
gem 'default_value_for'
gem 'tabs_on_rails'
gem 'kaminari'
gem 'distribution', '~> 0.6' # This gem is only used for GQL: NORMCDF()


# for etsource
gem 'git'
gem 'activerecord-import'

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

group :development do
  gem 'yard', '~> 0.7.2'
  gem 'annotate', :require => false
  gem 'active_reload'
end

group :test, :development do
  gem "rspec-rails", "~> 2.6.0"
  gem 'ruby-prof'
  gem 'ruby-debug19'
  gem 'guard'
  gem 'guard-rspec'
  gem 'hirb'
  gem 'wirble'
  gem 'awesome_print'
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