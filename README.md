# GOV.UK Forms Runner [![Ruby on Rails CI](https://github.com/alphagov/forms-runner/actions/workflows/rubyonrails.yml/badge.svg)](https://github.com/alphagov/forms-runner/actions/workflows/rubyonrails.yml) [![Deploy to GOV.UK PaaS](https://github.com/alphagov/forms-runner/actions/workflows/deploy.yml/badge.svg)](https://github.com/alphagov/forms-runner/actions/workflows/deploy.yml)

GOV.UK Forms is a service for creating forms. GOV.UK Forms Runner is a an application which displays those forms to end users so that they can be filled in. It's a Ruby on Rails application without a database. It uses redis for state.

## Before you start

To run the project you will need to install:

- [Ruby](https://www.ruby-lang.org/en/) - we use version 3 of Ruby. Before running the project, double check the [.ruby-version] file to see the exact version.
- [Node.js](https://nodejs.org/en/) - the frontend build requires Node.js. We use Node 18 LTS versions.
- a running [PostgreSQL](https://www.postgresql.org/) database

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
bin/setup
```

`bin/setup` is idempotent, so you can also run it whenever you pull new changes.

## Secrets vs Settings

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

### Running the app

You can either run the development task:

```bash
# Run the foreman dev server. This will also start the frontend dev task
bin/dev
```

or run the rails server:

```bash
# Run a local Rails server
bin/rails server

# When running the server, you can use any of the frontend tasks, e.g.:
npm run dev
```

For now, to test the API integration, you will also need to run the [API service](https://github.com/alphagov/forms-api).

## Explain how to use GOV.UK Notify

If you want to test the notify function, you will need to get a test API key
from the [notify service](https://www.notifications.service.gov.uk/) Add it as
an environment variable under `SETTINGS__GOVUK_NOTIFY__API_KEY=` or create/edit
a `config/settings/development.local.yml` and add the following to it.

```
# Settings for GOV.UK Notify api & email templates
govuk_notify:
  api_key: KEY_FROM_NOTIFY_SERVICE
```

#### Using Redis based sessions (optional)

Redis sessions can be enabled by providing the redis connection URL in the environment variable `REDIS_URL`

## Configuration and deployment

The forms-runner app is containerised (see [Dockerfile](https://github.com/alphagov/forms-runner/blob/main/Dockerfile)) and can be deployed however you would normally deploy a containerised app.

If you are planning to deploy to GOV.UK PaaS without using the container, you can see how this runs in our [Deployment CI action](https://github.com/alphagov/forms-runner/blob/main/.github/workflows/deploy.yml).

## Explain how to test the project

```bash
# Run the Ruby test suite
bin/rake
# To run the Javascript test suite, run
npm run test
```

### Running tasks before pushing

Before pushing code changes, it's a good idea to run the tests, use rubocop to format your code, and normalize the locales. We have a rake task for running all of these commands in parallel:

```bash
bin/rake run_code_quality_checks
```

## Updating versions

Use the [update_app_versions.sh script in forms-deploy](https://github.com/alphagov/forms-deploy/blob/main/support/update_app_versions.sh)

## Support

Raise a Github issue if you need support.

## Explain how users can contribute

We welcome contributions - please read [CONTRIBUTING.md](CONTRIBUTING.md) and the [alphagov Code of Conduct](https://github.com/alphagov/.github/blob/main/CODE_OF_CONDUCT.md) before contributing.

## License

We use the [MIT License](https://opensource.org/licenses/MIT).
