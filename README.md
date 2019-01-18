# Simple Server

[![Build Status](https://semaphoreci.com/api/v1/simpledotorg/simple-server/branches/master/badge.svg)](https://semaphoreci.com/simpledotorg/simple-server)

This is the backend for the Simple app to help track hypertensive patients across a population.

## Development Setup
First, you need to install ruby: https://www.ruby-lang.org/en/documentation/installation/
It is recommended to use rbenv to manage ruby versions: https://github.com/rbenv/rbenv
```bash
gem install bundler
bundle install
rake db:create db:setup db:migrate
```

To run simple-android app with the server running locally, you can use ngrok https://ngrok.com/
```bash
brew cask install ngrok
rails server
ngrok http 3000
```
The output of the ngrok command will have an url that can be used to access local-server. 
This url should be set as `qaApiEndpoint` in gradle.properties.


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

## Documentation
- API Documentation can be accessed at /api-docs on local server
  - They are also available https://api.simple.org/api-docs
- Architecture decisions are captured in ADR format and are available in /doc/arch

## Deployment
simple-server is deployed to the enviroment using capistrano.
```bash
bundle exec cap <enviroment> deploy
# eg: bundle exec cap staging deploy
```

Rake tasks can be run on the deployed server using capistrano as well. For example,
```bash
bundle exec cap staging deploy:rake task=db:seed
```

## Contributing

The contribution guidelines can be found [here](doc/contributing.md).