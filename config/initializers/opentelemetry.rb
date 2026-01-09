require "opentelemetry/sdk"
require "opentelemetry/instrumentation/all"

return unless ENV["ENABLE_OTEL"] == "true"

OpenTelemetry::SDK.configure do |c|
  instrumentation_config = { "OpenTelemetry::Instrumentation::Rack" => { untraced_endpoints: ["/up"] } }
  c.use_all(instrumentation_config)

  # Disable logging for Rake tasks to avoid cluttering output
  c.logger = Logger.new(File::NULL) if Rails.const_defined?(:Rake) && Rake.application.top_level_tasks.any?
end
