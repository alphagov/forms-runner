source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby file: ".ruby-version"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.2.2"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 6.4.3"

# Use Sentry (https://sentry.io/for/ruby/?platform=sentry.ruby.rails#)
gem "sentry-rails"
gem "sentry-ruby"

gem "config"

# Use GOV.UK Nofity api to send emails
gem "govuk_notify_rails"

# Use Redis for session storage
gem "redis"
gem "redis-session-store"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.5"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo"
gem "tzinfo-data"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# For forms-api
gem "activeresource"

# For GOV.UK branding
gem "govuk-components"
gem "govuk_design_system_formbuilder"

# Our own custom markdown renderer
gem "govuk-forms-markdown", github: "alphagov/govuk-forms-markdown", tag: "0.5.0"

# For compiling our frontend assets
gem "vite_rails"

# validate postcodes
gem "uk_postcode"

# For structured logging
gem "lograge"

# For AWS interactions
gem "aws-sdk-cloudwatch"
gem "aws-sdk-codepipeline", "~> 1.90"
gem "aws-sdk-s3"

# For sending submissions as CSV
gem "csv"

# The autocomplete component is not currently published as a gem, if changing
# the hash, also change in package.json
gem "dfe-autocomplete", require: "dfe/autocomplete", github: "DFE-Digital/dfe-autocomplete", ref: "11738c0e25778162e26eb7ab5e22a6ffce671b08"

gem "solid_queue", "~> 1.0"

# Use Mission Control - Jobs to inspect Solid Queue jobs
gem "mission_control-jobs"
gem "propshaft" # needed as we use vite_rails

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri mingw x64_mingw]

  gem "factory_bot_rails"
  gem "faker"

  # Support for locale tasks tests
  gem "i18n-tasks", "~> 1.0.14"

  gem "rspec-rails"
  gem "rubocop-govuk", require: false

  # For security auditing gem vulnerabilities. RUN IN CI
  gem "bundler-audit", "~> 0.9.2"

  # For detecting security vulnerabilities in Ruby on Rails applications via static analysis.
  gem "brakeman", "~> 6.2"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "rails-controller-testing"
  gem "selenium-webdriver"
  gem "simplecov"

  # axe-core for running automated accessibility checks
  gem "axe-core-rspec"
end
