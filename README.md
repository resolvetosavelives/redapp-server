# Simple Server

[![Build Status](https://semaphoreci.com/api/v1/resolvetosavelives/simple-server/branches/master/badge.svg)](https://semaphoreci.com/resolvetosavelives/simple-server)

This is the backend for the Simple app to help track hypertensive patients across a population.

## Development Setup
First, you need to install ruby: https://www.ruby-lang.org/en/documentation/installation
It is recommended to use rbenv to manage ruby versions: https://github.com/rbenv/rbenv
```bash
gem install bundler
bundle install
rake yarn:install
rake db:create db:setup db:migrate
```

To run [simple-android](https://github.com/simpledotorg/simple-android/) app with the server running locally, you can use ngrok https://ngrok.com
```bash
brew cask install ngrok
rails server
ngrok http 3000
```
The output of the ngrok command will have an url that can be used to access local-server. 
This url should be set as `qaApiEndpoint` in gradle.properties.

#### Workers

We use [sidekiq](https://github.com/mperham/sidekiq) to run async tasks. To run, first make sure that redis (>4) is installed:

```bash
brew install redis

# after installing ensure your redis version is >4
redis-server -v
```

Start the sidekiq process by running

```bash
bundle exec sidekiq
```

### Testing Email

We use [Mailcatcher](https://mailcatcher.me/) for testing email in development. Please use the
following to set it up on your machine.

_Note: Please don't add Mailcatcher to the `Gemfile`, as it causes conflicts._

```bash
gem install mailcatcher
mailcatcher
```

Now you should be able to see test emails at http://localhost:1080

## Configuring
The app can be configured using a .env file. Look at .env.development for sample configuration

## Running the application locally
The application will start at http://localhost:3000.
```bash
RAILS_ENV=development bundle exec rails server
```

## Running the tests
```bash
RAILS_ENV=test bundle exec rspec
```

## Generating seed data

To generate seed data for the local environment, execute the following command from the project root:

```bash
bundle exec rake "generate:seed[N]"
```

where `N` is the number of months to generate seed data for. For example,

```shell
bundle exec rake "generate:seed[6]"
```

will generate seed data for 6 months.

Note: 

* For the `development` environment, this will truncate existing data and seed the database
from scratch.
* Please refer to `config/seed.yml` to set the multiplier values to control the volume of seed data generated.

## Creating an admin user

Run the following command from the project root to create a new dashboard admin:
```bash
bundle exec rake create_admin_user["<name>","<email>","<password>"]
```

## Documentation

### API

API Documentation can be accessed at `/api-docs` on local server and hosted at https://api.simple.org/api-docs

### ADRs

Architecture decisions are captured in ADR format and are available in `/doc/arch`

### ERD (Entity-Relationship Diagram)

These are not actively committed into the repository. But can be generated by running `bundle exec erd`


## Deployment
* `simple-server` is deployed for a specific country and environment using capistrano.
* Make sure you add your SSH keys as single sign-on so that `cap` doesn't get confused when there's more than 1 instance to deal with. You can do this simply by running `ssh-add -K ~/.ssh/id_rsa`. 

##### Capistrano Multi-config 
* We use capistrano [multi-config](https://github.com/railsware/capistrano-multiconfig) to do multi-country deploys. 
* All `cap` commands are namespaced with the country name. For eg: `bundle exec india:sandbox deploy`. 
* The available country names are listed under `config/deploy`. The subsequent envs, under the country directory, like `config/deploy/india/sandbox.rb`

```bash
bundle exec cap <country_name>:<enviroment> deploy
# eg: bundle exec cap india:staging deploy
# or, bundle exec cap bangladesh:production deploy
```

Rake tasks can be run on the deployed server using capistrano as well. For example,
```bash
bundle exec cap india:staging deploy:rake task=db:seed
```

## Contributing

The contribution guidelines can be found [here](doc/contributing.md).
