source 'https://rubygems.org'

ruby '2.5.1'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'activerecord-import'
gem 'bcrypt', '~> 3.1', '>= 3.1.11'
gem 'bootstrap', '~> 4.3.1'
gem 'bootstrap_form', '>= 4.1.0'
gem 'connection_pool'
gem 'data-anonymization', require: false
gem 'data_migrate'
gem 'devise', '>= 4.7.1'
gem 'devise_invitable', '~> 1.7.0'
gem 'discard', '~> 1.0'
gem 'dotenv-rails'
gem 'factory_bot_rails', require: false
gem 'faker', require: false
gem 'friendly_id', '~> 5.2.4'
gem 'groupdate'
gem 'http'
gem 'http_accept_language'
gem 'imgkit'
gem 'jbuilder', '~> 2.5'
gem 'jquery-rails'
gem 'kaminari'
gem 'lodash-rails'
gem 'newrelic_rpm'
gem 'passenger'
gem 'pg', '>= 0.18', '< 2.0'
gem 'phonelib'
gem 'pry-rails'
gem 'pundit'
gem 'rails', '~> 5.1.6.2'
gem 'react-rails'
gem 'redis'
gem 'redis-rails'
gem 'roo', '~> 2.8.0'
gem 'rspec-rails', '~> 3.7'
gem 'rswag', '~> 1.6.0'
gem 'sassc-rails'
gem 'scenic'
gem 'sentry-raven'
gem 'sidekiq'
gem 'sidekiq-throttled'
gem 'timecop', '~> 0.9.0', require: false
gem 'twilio-ruby', '~> 5.10', '>= 5.10.3'
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
gem 'uglifier', '>= 1.3.0'
gem 'uuidtools', require: false
gem 'whenever', require: false
gem 'wkhtmltoimage-binary'

group :development, :test do
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'capistrano', '~> 3.10'
  gem 'capistrano-db-tasks', require: false
  gem 'capistrano-multiconfig', require: true
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'capistrano-rails-console', require: false
  gem 'capistrano-rbenv'
  gem 'capistrano-sidekiq', require: false
  gem 'parallel_tests', group: %i[development test]
  gem 'rails-controller-testing'
  gem 'rb-readline'
  gem 'shoulda-matchers', '~> 4.1.2'
end

group :development do
  gem 'guard-rspec', require: false
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'rails-erd'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'capybara'
  gem 'fakeredis', require: false
  gem 'generator_spec'
  gem 'launchy'
  gem 'puma'
  gem 'rspec-sidekiq'
  gem 'simplecov', require: false
  gem 'webdrivers'
  gem 'webmock'
end
