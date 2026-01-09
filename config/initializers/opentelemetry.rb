require 'opentelemetry/sdk'
require 'opentelemetry/instrumentation/all'

return unless defined?(Rails::Server) || ENV['ENABLE_OTEL'] == 'true'

OpenTelemetry::SDK.configure do |c|
  c.service_name = 'forms-runner'

  c.add_span_processor(
    # Use the BatchSpanProcessor to send traces in groups instead of one at a time
    OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
      # Use the default OLTP Exporter to send traces to the ADOT Collector
      OpenTelemetry::Exporter::OTLP::Exporter.new(
        # The OpenTelemetry Collector is running as a sidecar and listening on port 4318
        endpoint:"http://127.0.0.1:4318/v1/traces"
      )
    )
  )

  # The X-Ray Propagator injects the X-Ray Tracing Header into downstream calls
  c.propagators = [OpenTelemetry::Propagator::XRay::TextMapPropagator.new]

  c.use_all()
end
