require "./app/lib/json_log_formatter"

unless Rails.env.development?
  Rails.application.configure do
    #### LOGGING CONFIGURATION ####
    config.log_level = :info

    # Use JSON log formatter for better support in Splunk. To use conventional
    # logging use the Logger::Formatter.new.
    config.log_formatter = JsonLogFormatter.new

    if ENV["RAILS_LOG_TO_STDOUT"].present?
      config.logger = ActiveSupport::Logger.new($stdout)
      config.logger.formatter = config.log_formatter
    end

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
