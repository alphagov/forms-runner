require_relative "boot"

require "rails/all"

# Add here so we don't need to require it in initializers
require './app/lib/hosting_environment'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FormsRunner
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.generators do |g|
      g.test_framework :rspec
    end

    # when generating components, add preview too
    # config.view_component.generate.preview = true

    # when generating components, a locale file for each supported language
    # config.view_component.generate.locale = true
    # config.view_component.generate_distinct_locale_files = true
  end
end
