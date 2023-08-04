# GOV.UK Forms Runner [![Tests](https://github.com/alphagov/forms-runner/actions/workflows/test.yml/badge.svg)](https://github.com/alphagov/forms-runner/actions/workflows/test.yml)

GOV.UK Forms is a service for creating forms. GOV.UK Forms Runner is a an application which displays those forms to end users so that they can be filled in. It's a Ruby on Rails application without a database. It uses redis for state.

## Before you start

To run the project you will need to install:

- [Ruby](https://www.ruby-lang.org/en/) - we use version 3 of Ruby. Before running the project, double check the [.ruby-version](.ruby-version) file to see the exact version.
- [Node.js](https://nodejs.org/en/) - the frontend build requires Node.js. We use Node 18 LTS versions.

We recommend using a version manager to install and manage these, such as:

- [RVM](https://rvm.io/) or [rbenv](https://github.com/rbenv/rbenv) for Ruby
- [nvm](https://github.com/nvm-sh/nvm) for Node.js
- [asdf](https://github.com/asdf-vm/asdf) for both

## Getting started

### Installing for the first time

```bash
# 1. Clone the git repository and change directory to the new folder
git clone git@github.com:alphagov/forms-runner.git
cd forms-runner

# 2. Run the setup script
./bin/setup
```

### Running the app

You can either run the development task:

```bash
# Run the foreman dev server. This will also start the frontend dev task
./bin/dev
```

or run the rails server:

```bash
# Run a local Rails server
./bin/rails server

# When running the server, you can use any of the frontend tasks, e.g.:
npm run dev
```

You will also need to run the [forms-api service](https://github.com/alphagov/forms-api), as this app needs the API to create and access forms.

## Development tools

### Running the tests

The app tests are written with [rspec-rails], and you can run them with:

```bash
bundle exec rspec
```

[rspec-rails]: https://github.com/rspec/rspec-rails

### Linting

We use [RuboCop GOV.UK] for linting code. To autocorrect issues, run:

```bash
bundle exec rubocop -A
```

We also use the [i18n-tasks] tool to keep our locales files in a consistent order. When the tests run, they will check if the locale files are normalised and fail if they are not. To fix the locale files automatically, you can run:

```bash
bundle exec i18n-tasks normalize
```

On GitHub pull requests, we also check our dependencies for security issues using [bundler-audit]. You can run this locally with:

```bash
bundle audit
```

[RuboCop GOV.UK]: https://github.com/alphagov/rubocop-govuk
[i18n-tasks]: https://github.com/glebm/i18n-tasks
[bundle-audit]: https://github.com/rubysec/bundler-audit

### Running tasks with Rake

We have a [Rakefile](./Rakefile) that is set up to follow the [GOV.UK conventions for Rails applications].

To lint your changes and run tests with one command, you can run:

```bash
bundle exec rake
```

[GOV.UK conventions for Rails applications]: https://docs.publishing.service.gov.uk/manual/configure-linting.html#configuring-rails

## Changing configuration

### Changing settings

Refer to the [the config gem](https://github.com/railsconfig/config#accessing-the-settings-object) to understand the `file based settings` loading order.

To override file based via `Machine based env variables settings`

```bash
cat config/settings.yml
file
  based
    settings
      env1: 'foo'
```

```bash
export SETTINGS__FILE__BASED__SETTINGS__ENV1="bar"
```

```ruby
puts Settings.file.based.setting.env1
bar
```

Refer to the [settings file](config/settings.yml) for all the settings required to run this app

### Environment variables

| Name        | Purpose                      |
| ----------- | ---------------------------- |
| `REDIS_URL` | The URL for Redis (optional) |

### Configuring Redis

You can enable Redis sessions by providing the Redis connection URL in the environment variable `REDIS_URL`.

### Configuring GOV.UK Notify

We use [GOV.UK Notify] to send emails from our apps.

If you want to test the Notify functionality locally, you will need to get a test API key from the Notify service. Add it as an environment variable under `SETTINGS__GOVUK_NOTIFY__API_KEY` or add it to a local config file:

```
# config/settings.local.yml

# Settings for GOV.UK Notify api & email templates
govuk_notify:
  api_key: <API key from Notify>
```

[GOV.UK Notify]: https://www.notifications.service.gov.uk/

### Configuring Sentry

We use [Sentry] to catch and alert us about exceptions in production apps.

We currently have a very basic setup for Sentry in this repo for testing, which we will continue to build upon.

In order to use Sentry locally, you will need to:

1. Sign in to Sentry using your work Google account.
2. Create a new project.
3. Add the Sentry DSN to your environment as `SETTINGS__SENTRY__DSN`, or add it to a local config file:

```
# config/settings.local.yml

sentry:
  DSN: <DSN from Sentry>
```

If you want to deliberately raise an exception to test, uncomment out the triggers in the [Sentry initializer script](config/initializers/sentry.rb). Whenever you run the app, errors will be raised and should also come through on Sentry.

[Sentry]: https://sentry.io

## Deploying apps

The forms-runner app is containerised (see [Dockerfile](Dockerfile)) and can be deployed in the same way you'd normally deploy a containerised app.

We host our apps using Amazon Web Services (AWS). You can [read about how deployments happen on our team wiki](https://github.com/alphagov/forms-team/wiki/Deploying-code-changes-AWS), if you have access.

### Logging

- You should should configure HTTP access logs in [the application config](./config/application.rb), using [Lograge](https://github.com/roidrage/lograge).
- You should use the [LogEventService](./app/services/log_event_service.rb) and [EventLogger](./app/lib/event_logger.rb) to create any custom log messages. This is independent to any Lograge configuration.
- The output format is JSON, using the [JsonLogFormatter](./app/lib/json_log_formatter.rb) to enable simpler searching and visbility, especially in Splunk.
- Do not use [log_tags](https://guides.rubyonrails.org/configuring.html#config-log-tags) since it breaks the JSON formatting produced by Lograge.

### Updating Docker files

To update the version of [Alpine Linux] and Ruby used in the Dockerfile, use the [update_app_versions.sh script in forms-deploy](https://github.com/alphagov/forms-deploy/blob/main/support/update_app_versions.sh)

[Alpine Linux]: https://www.alpinelinux.org/

## Support

Raise a GitHub issue if you need support.

## How to contribute

We welcome contributions - please read [CONTRIBUTING.md](CONTRIBUTING.md) and the [alphagov Code of Conduct](https://github.com/alphagov/.github/blob/main/CODE_OF_CONDUCT.md) before contributing.

## License

We use the [MIT License](https://opensource.org/licenses/MIT).
