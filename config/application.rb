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
require "./app/lib/hosting_environment"
require "./app/lib/json_log_formatter"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FormsRunner
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

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

    config.action_view.default_form_builder = GOVUKDesignSystemFormBuilder::FormBuilder

    # Use custom error pages
    config.exceptions_app = routes
    config.view_component.preview_paths = [Rails.root.join("spec/components")]
    config.view_component.preview_route = "/preview"
    config.view_component.preview_controller = "ComponentPreviewController"
    # Replace with value which will be true in local dev
    config.view_component.show_previews = HostingEnvironment.test_environment?

    #### LOGGING CONFIGURATION ####

    # Use JSON log formatter for better support in Splunk. To use conventional
    # logging use the Logger::Formatter.new.
    config.log_formatter = JsonLogFormatter.new

    # Lograge is used to format the standard HTTP request logging
    config.lograge.enabled = true
    config.lograge.formatter = Lograge::Formatters::Json.new

    # Lograge suppresses the default Rails request logging. Set this to true to
    # make lograge output it which includes some extra debugging
    # information.
    config.lograge.keep_original_rails_log = false

    config.lograge.custom_options = lambda do |event|
      {}.tap do |h|
        h[:host] = event.payload[:host]
        h[:request_id] = event.payload[:request_id]
        h[:form_id] = event.payload[:form_id] if event.payload[:form_id]
        h[:page_id] = event.payload[:page_id] if event.payload[:page_id]
        h[:page_slug] = event.payload[:page_slug] if event.payload[:page_slug]
        h[:exception] = event.payload[:exception] if event.payload[:exception]
        h[:session_id_hash] = event.payload[:session_id_hash] if event.payload[:session_id_hash]
      end
    end
  end
end
