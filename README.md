# GOV.UK Forms Runner [![Ruby on Rails CI](https://github.com/alphagov/forms-runner/actions/workflows/rubyonrails.yml/badge.svg)](https://github.com/alphagov/forms-runner/actions/workflows/rubyonrails.yml) [![Deploy to GOV.UK PaaS](https://github.com/alphagov/forms-runner/actions/workflows/deploy.yml/badge.svg)](https://github.com/alphagov/forms-runner/actions/workflows/deploy.yml)

GOV.UK Forms is a service for creating forms. GOV.UK Forms Runner is a an application which displays those forms to end users so that they can be filled in. It's a Ruby on Rails application built on a PostgreSQL database.

## Before you start

To run the project you will need to install:

- [Ruby](https://www.ruby-lang.org/en/) - we use version 3 of Ruby. Before running the project, double check the [.ruby-version] file to see the exact version.
- [Node.js](https://nodejs.org/en/) - the frontend build requires Node.js. We use Node 16 LTS versions.
- a running [PostgreSQL](https://www.postgresql.org/) database
- [Yarn](https://yarnpkg.com/) - we use Yarn rather than `npm` to install and run the frontend.

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

# 2. Install the ruby dependencies
bundle install

# 3. Set up the database
# You can check the DB details in .env.development and overide them if needed using .env.development.local
rake db:prepare

# 4. Install the node dependencies
yarn

# 5. Run the frontend build tasks
yarn build & yarn build:css
```

#### Add Notify API Keys (Optional)
If you want to test the notify function, you will need to get a test API key
from the [notify service](https://www.notifications.service.gov.uk/) Add it as
an environment vairable under `NOTIFY_API_KEY=` in `.env.development.local` and
use the 'api intergration' tab on notify dashboard to check emails sent.

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
yarn dev
```

For now, to test the API integration, you will also need to run the [API service](https://github.com/alphagov/forms-api).

## Configuration and deployment

TODO: Add these details once we've got our deployment running.

## Explain how to test the project

```bash
# Run the Ruby test suite
bin/rake
# To run the Javascript test suite, run
yarn test
# To run the end-to-end tests, run
yarn cypress
```

## Support

Raise a Github issue if you need support.

## Explain how users can contribute

We welcome contributions - please read [CONTRIBUTING.md](CONTRIBUTING.md) and the [alphagov Code of Conduct](https://github.com/alphagov/.github/blob/main/CODE_OF_CONDUCT.md) before contributing.

## License

We use the [MIT License](https://opensource.org/licenses/MIT).
