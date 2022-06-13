require_relative "boot"

require "rails/all"

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
    #
    # Get redis url based on VCAP_SERVICES or REDIS_URL depending on environment
    # GovPaaS provides the URI in VCAP_SERVICES

    redis_url = if ENV['VCAP_SERVICES']
                  vcap_services = JSON.parse(ENV['VCAP_SERVICES'])
                  if(vcap_services["redis"])
                    vcap_services["redis"][0]["credentials"]["uri"]
                  end
                elsif ENV['REDIS_URL']
                  ENV['REDIS_URL']
                end

    if redis_url
      config.session_store :redis_session_store,
        servers: redis_url,
        key: '_app_session_key'
    end
  end
end
