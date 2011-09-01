source 'http://rubygems.org'
source 'http://gems.github.com'

gem 'rails', '3.0.9'
gem 'jquery-rails'
gem 'haml', '~>3.1.1'
gem 'sass', '~>3.1.1'
gem 'rake', '0.9.2' # 0.9 breaks things

gem 'authlogic', :git => 'git://github.com/odorcicd/authlogic.git', :branch => 'rails3'
gem 'bluecloth'
gem 'formtastic'
gem 'http_status_exceptions', :git => 'git://github.com/japetheape/http_status_exceptions.git' 
gem 'paper_trail', '>= 1.6.4'
gem 'ruby-graphviz', :require => "graphviz"
gem 'treetop', '1.4.8'
gem 'default_value_for'
gem 'acts_as_list'
gem 'tabs_on_rails'
gem 'kaminari'

# javascript
gem 'sprockets'
gem 'sprockets-rails'
gem 'rack-sprockets'
gem 'yui-compressor'

# supporting gems
gem 'airbrake', '3.0.2'

# system gems
# gem 'thinking-sphinx', '>=2.0.1'
gem 'mysql2', '~>0.2.6'
gem 'dalli'
gem 'memcache-client'
gem 'mongrel', '1.2.0.pre2'
gem 'term-ansicolor', :require => false
gem 'highline', :require => false

# Optional gems that were commented in environment.rb
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
  gem 'watchr'
  gem 'spork'
  gem 'hirb'
  gem 'wirble'
  gem 'awesome_print'
end

group :test do
  gem 'factory_girl_rails', "1.1.rc1", :require => false
  gem 'shoulda-matchers'
  gem 'webrat'
  gem 'simplecov', :require => false
end