require "capistrano/setup"
require "capistrano/deploy"
require "capistrano/rails/console"

require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

require "capistrano/multiconfig"
require "capistrano/rbenv"
require "capistrano/rails"
require "capistrano/passenger"
require "capistrano/sidekiq"
require "capistrano-db-tasks"
require "capistrano/data_migrate"

require "whenever/capistrano"

Dir.glob("lib/capistrano/tasks/*.rake").each(&method(:import))
