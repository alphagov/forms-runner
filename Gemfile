source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.0.6"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 6.3.0"

# Use Sentry (https://sentry.io/for/ruby/?platform=sentry.ruby.rails#)
gem "sentry-rails"
gem "sentry-ruby"

gem "dotenv-rails", groups: %i[development test]

gem "config"

# Use GOV.UK Nofity api to send emails
gem "govuk_notify_rails"

# Use Redis for session storage
gem "redis"
gem "redis-session-store"

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
gem "govuk-components", "~> 4.1.0"
gem "govuk_design_system_formbuilder", "~> 4.1.0"

# For compiling our frontend assets
gem "vite_rails"

# validate postcodes
gem "uk_postcode"

# For structured logging
gem "lograge"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri mingw x64_mingw]

  gem "factory_bot_rails"
  gem "faker"

  # Support for locale tasks tests
  gem "i18n-tasks", "~> 1.0.12"

  gem "rspec-rails"
  gem "rubocop-govuk", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
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

# For security auditing gem vulnerabilities. RUN IN CI
gem "bundler-audit", "~> 0.9.0"

# For detecting security vulnerabilities in Ruby on Rails applications via static analysis.
gem "brakeman", "~> 6.0"
