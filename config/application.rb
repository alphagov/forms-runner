require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
# require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

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

    if ENV["VCAP_SERVICES"]
      vcap_services = JSON.parse(ENV["VCAP_SERVICES"])
      if vcap_services["redis"]
        host = vcap_services["redis"][0]["credentials"]["host"]
        password = vcap_services["redis"][0]["credentials"]["password"]
        port = vcap_services["redis"][0]["credentials"]["port"]

        config.session_store :redis_session_store,
                             key: "_app_session_key",
                             redis: {
                               host:,
                               password:,
                               port:,
                               ssl: true,
                             },
                             on_redis_down: ->(_e, _env, _sid) { Rails.logger.debug "Redis down" }
      end
    elsif ENV["REDIS_URL"]
      config.session_store :redis_session_store,
                           key: "_app_session_key",
                           redis: {
                             url: ENV["REDIS_URL"],
                           },
                           on_redis_down: ->(_e, _env, _sid) { Rails.logger.debug "Redis down" }
    end

    # Use custom error pages
    config.exceptions_app = routes
  end
end
