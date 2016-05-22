source "http://rubygems.org"

gem 'activemodel', "> 3", '< 4'
gem 'rack', '~> 1.4'

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development do
  gem 'activerecord', "~> 3", '< 4'
  gem 'rack-test'
  gem 'rake', '~> 10.0'
  gem 'yard'
  gem 'sqlite3'
  gem "rspec", "~> 3.4"
  gem "bundler", "~> 1.0"
  gem "jeweler", '~> 2.1'
end
