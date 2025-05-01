require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
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
require "./app/lib/application_logger"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FormsRunner
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks generators])

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
    config.log_level = :info

    # Lograge is used to format the standard HTTP request logging
    config.lograge.enabled = true
    config.lograge.formatter = Lograge::Formatters::Json.new
    config.lograge.logger = ActiveSupport::Logger.new($stdout)

    # Lograge suppresses the default Rails request logging. Set this to true to
    # make lograge output it which includes some extra debugging
    # information.
    config.lograge.keep_original_rails_log = false

    config.lograge.custom_options = lambda do |event|
      CurrentRequestLoggingAttributes.as_hash.merge(exception: event.payload[:exception]).compact
    end

    # Use custom logger and formatter to log in JSON with request context fields. To use conventional
    # logging use ActiveSupport::Logger.new($stdout) with formatter Logger::Formatter.new.
    config.logger = ApplicationLogger.new($stdout)
    config.logger.formatter = JsonLogFormatter.new

    # custom configuration for the SES mailer delivery method
    config.x.aws_ses_form_submission_mailer.delivery_method = :aws_ses

    # Prevent ActiveRecord::PreparedStatementCacheExpired errors when adding columns
    config.active_record.enumerate_columns_in_select_statements = true

    # Set ActiveRecord Encryption keys
    config.active_record.encryption.primary_key = Settings.active_record_encryption.primary_key
    config.active_record.encryption.deterministic_key = Settings.active_record_encryption.deterministic_key
    config.active_record.encryption.key_derivation_salt = Settings.active_record_encryption.key_derivation_salt
    # TODO: remove this when all sensitive data is encrypted
    # See https://guides.rubyonrails.org/active_record_encryption.html#support-for-unencrypted-data
    config.active_record.encryption.support_unencrypted_data = true

    config.after_initialize do
      # Localization isn't available if this is called from an initializer
      GOVUKDesignSystemFormBuilder.configure do |conf|
        conf.default_submit_button_text = I18n.t("govuk_design_system_formbuilder.default_submit_button_text")
        conf.default_error_summary_title = I18n.t("govuk_design_system_formbuilder.default_error_summary_title")
        conf.default_radio_divider_text = I18n.t("govuk_design_system_formbuilder.default_radio_divider_text")
        conf.default_check_box_divider_text = I18n.t("govuk_design_system_formbuilder.default_check_box_divider_text")
      end
    end
  end
end
