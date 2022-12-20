# GOV.UK Forms Runner [![Ruby on Rails CI](https://github.com/alphagov/forms-runner/actions/workflows/rubyonrails.yml/badge.svg)](https://github.com/alphagov/forms-runner/actions/workflows/rubyonrails.yml) [![Deploy to GOV.UK PaaS](https://github.com/alphagov/forms-runner/actions/workflows/deploy.yml/badge.svg)](https://github.com/alphagov/forms-runner/actions/workflows/deploy.yml)

GOV.UK Forms is a service for creating forms. GOV.UK Forms Runner is a an application which displays those forms to end users so that they can be filled in. It's a Ruby on Rails application without a database. It uses redis for state.

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

# 2. Run the setup script
bin/setup
```

`bin/setup` is idempotent, so you can also run it whenever you pull new changes.

#### Add Notify API Keys (Optional)

If you want to test the notify function, you will need to get a test API key
from the [notify service](https://www.notifications.service.gov.uk/) Add it as
an environment vairable under `NOTIFY_API_KEY=` in `.env.development.local` and
use the 'api intergration' tab on notify dashboard to check emails sent.

### Environment variables

| Name                  | Purpose                                                      |
| --------------------- | ------------------------------------------------------------ |
| `REDIS_URL`           | The URL for Redis (optional)                                 |
| `SENTRY_DSN`          | The DSN provided by Sentry                                   |
| `API_BASE`            | The base url for the API - E.g. `http://localhost:9090`      |
| `SERVICE_UNAVAILABLE` | All pages will render 'Service unavailable' if set to `true` |
| `API_KEY`             | The API key for authentication                               |

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

#### Using Redis based sessions (optional)

Redis sessions can be enabled by providing the redis connection URL in the environment variable `REDIS_URL`

## Configuration and deployment

TODO: Add these details once we've got our deployment running.

## Explain how to test the project

```bash
# Run the Ruby test suite
bin/rake
# To run the Javascript test suite, run
yarn test
```

## Support

Raise a Github issue if you need support.

## Explain how users can contribute

We welcome contributions - please read [CONTRIBUTING.md](CONTRIBUTING.md) and the [alphagov Code of Conduct](https://github.com/alphagov/.github/blob/main/CODE_OF_CONDUCT.md) before contributing.

## License

We use the [MIT License](https://opensource.org/licenses/MIT).
