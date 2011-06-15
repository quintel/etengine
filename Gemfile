source 'http://rubygems.org'
source 'http://gems.github.com'

gem 'rails', '3.0.8'
gem 'jquery-rails'
gem 'haml', '~>3.1.1'
gem 'sass', '~>3.1.1'
gem 'rake', '0.8.7' # 0.9 breaks things

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

# javascript
gem 'sprockets'
gem 'sprockets-rails'
gem 'rack-sprockets'
gem 'yui-compressor'

# supporting gems
gem 'hoptoad_notifier', '2.4.2'

# system gems
gem 'thinking-sphinx', '>=2.0.1'
gem 'mysql2', '~>0.2.6'
gem 'memcache-client'
gem 'mongrel', '1.2.0.pre2'

# Optional gems that were commented in environment.rb
gem 'rubyzip', '0.9.4'

group :development do
  gem 'yard', '0.5.4'
  gem 'annotate', :require => false
end

group :test, :development do
  gem "rspec-rails", "~> 2.6.0"
  gem 'ruby-debug19'
  gem 'watchr'
  gem 'spork'
end

group :test do
  gem 'factory_girl_rails', :require => false
  gem 'shoulda-matchers'
  gem 'webrat'
  gem 'simplecov', :require => false
end