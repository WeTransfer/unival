source "http://rubygems.org"

# We test both with AR 4 and AR3, see gemfiles/ for more.
# To run specs against specific versions of dependencies, use
#
#   $ BUNDLE_GEMFILE=gemfiles/Gemfile.rails-4.1.x bundle exec rake
#
# etc.
gem 'activemodel', "> 3"
gem 'rack', '~> 1.4'

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development do
  gem 'activerecord'
  gem 'rack-test'
  gem 'rake', '~> 10.0'
  gem 'yard'
  gem 'sqlite3'
  gem "rspec", "~> 3.4"
  gem "bundler", "~> 1.0"
  gem "jeweler"
end
