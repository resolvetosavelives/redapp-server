source "https://rubygems.org"

ruby "2.5.1"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem "dotenv-rails"

gem "active_record_union"
gem "activerecord-import"
gem "amazing_print"
gem "auto_strip_attributes"
gem "bcrypt", "~> 3.1", ">= 3.1.11"
gem "bootsnap", require: false
gem "bootstrap", "~> 4.5.0"
gem "bootstrap_form", ">= 4.5.0"
gem "connection_pool"
gem "data-anonymization", require: false
gem "data_migrate"
gem "ddtrace"
gem "devise", ">= 4.7.1"
gem "devise_invitable", "~> 1.7.0"
gem "discard", "~> 1.0"
gem "dogstatsd-ruby"
gem "factory_bot_rails", "~> 4.8", require: false
gem "faker", require: false
gem "flipper"
gem "flipper-active_record"
gem "flipper-ui"
gem "friendly_id", "~> 5.2.4"
gem "github-ds"
gem "groupdate"
gem "http"
gem "http_accept_language"
gem "imgkit"
gem "jbuilder", "~> 2.5"
gem "jquery-rails"
gem "kaminari"
gem "lodash-rails"
gem "lograge"
gem "ougai"
gem "passenger"
gem "pg", ">= 0.18", "< 2.0"
gem "pg_search"
gem "pg_ltree", "1.1.8"
gem "phonelib"
gem "pry-rails"
gem "rack-mini-profiler"
gem "rails", "5.2.4.4"
gem "redis"
gem "redis-rails"
gem "request_store"
gem "request_store-sidekiq"
gem "roo", "~> 2.8.0"
gem "rspec-rails", "~> 3.7"
gem "rswag", "~> 1.6.0"
gem "sassc-rails"
gem "scenic"
gem "sentry-raven"
gem "sidekiq"
gem "sidekiq-statsd"
gem "sidekiq-throttled"
gem "slack-notifier"
gem "strong_password", "~> 0.0.8"
gem "timecop", "~> 0.9.0", require: false
gem "twilio-ruby", "~> 5.10", ">= 5.10.3"
gem "uglifier", ">= 1.3.0"
gem "uuidtools", require: false
gem "view_component"
gem "whenever", require: false
gem "wkhtmltoimage-binary"
gem "memery"
gem "bootstrap-select-rails"
gem "render_async"
gem "rack-attack"

group :development, :test do
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "capistrano", "3.11.0"
  gem "capistrano-db-tasks", require: false
  gem "capistrano-multiconfig", require: true
  gem "capistrano-passenger"
  gem "capistrano-rails"
  gem "capistrano-rails-console", require: false
  gem "capistrano-rbenv"
  gem "capistrano-template", require: false
  gem "parallel_tests", group: %i[development test]
  gem "rails-controller-testing"
  gem "rb-readline"
  gem "shoulda-matchers", "~> 4.1.2"
  gem "standard"
end

group :development do
  gem "guard-rspec", require: false
  gem "listen", ">= 3.0.5", "< 3.2"
  gem "rails-erd"
  gem "spring"
  gem "spring-commands-rspec"
  gem "web-console", ">= 3.3.0"
  # For memory profiling
  gem "memory_profiler"
  # For call-stack profiling flamegraphs
  gem "flamegraph"
  gem "stackprof"
end

group :test do
  gem "capybara"
  gem "fakeredis", require: false
  gem "generator_spec"
  gem "launchy"
  gem "puma"
  gem "rspec-sidekiq"
  gem "simplecov", require: false
  gem "webdrivers"
  gem "webmock"
end
