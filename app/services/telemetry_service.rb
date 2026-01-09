class TelemetryService
  # OpenTelemetry tracing service for adding span attributes
  # Follows the same pattern as CloudWatchService and LogEventService
  #
  # We are heavily using attributes, not events because X-Ray does not support events
  # see: https://github.com/aws-observability/aws-otel-collector/issues/821

  # Set request-level attributes for journey tracking
  # Call from ApplicationController to add form/session context to all spans
  def self.set_request_attributes(attrs)
    return unless defined?(OpenTelemetry)

    # Ensure all values are primitives (string, number, boolean, nil)
    sanitized = attrs.compact.transform_values { |v| sanitize_attribute_value(v) }
    current_span.add_attributes(sanitized.transform_keys(&:to_s))
  rescue StandardError => e
    Sentry.capture_exception(e) if defined?(Sentry)
  end

  # Set question-level attributes on page requests
  # Call from PageController to add question context to all page spans
  def self.set_question_attributes(step, form)
    return unless defined?(OpenTelemetry)

    attrs = {
      "question.type" => step.question.class.name,
      "question.id" => step.page_id,
      "question.text" => step.question_text,
      "question.answer_type" => step.page&.answer_type,
      "question.number" => step.page_number,
      "question.is_optional" => step.question.is_optional?,
      "question.is_repeatable" => step.repeatable?,
      "form.submission_type" => form.submission_type,
    }.compact

    sanitized = attrs.transform_values { |v| sanitize_attribute_value(v) }
    current_span.add_attributes(sanitized)
  rescue StandardError => e
    Sentry.capture_exception(e) if defined?(Sentry)
  end

  def self.record_validation_failure(step)
    return unless defined?(OpenTelemetry)

    attrs = {
      "validation.failed" => true,
      "validation.error_count" => step.question.errors.count,
      "validation.errors" => step.question.errors.full_messages.join(", "),
      "validation.error_attributes" => step.question.errors.attribute_names.map(&:to_s).join(", "),
    }

    sanitized = attrs.transform_values { |v| sanitize_attribute_value(v) }
    current_span.add_attributes(sanitized)
  rescue StandardError => e
    # Silently fail - don't break the app if telemetry has issues
    Sentry.capture_exception(e) if defined?(Sentry)
  end

  def self.record_validation_success
    return unless defined?(OpenTelemetry)

    current_span.set_attribute("validation.passed", true)
  rescue StandardError => e
    Sentry.capture_exception(e) if defined?(Sentry)
  end

  # Create a custom span for wrapping important operations
  # Usage: TelemetryService.trace('operation.name', attributes: {...}) { ... }
  def self.trace(span_name, attributes: {}, &block)
    return yield(NoOpSpan.new) unless defined?(OpenTelemetry)

    # Get tracer
    tracer = OpenTelemetry.tracer_provider.tracer("forms-runner")

    # Sanitize attributes to ensure they're primitives
    sanitized = attributes.compact.transform_values { |v| sanitize_attribute_value(v) }

    tracer.in_span(span_name, attributes: sanitized, &block)
  rescue StandardError => e
    Sentry.capture_exception(e) if defined?(Sentry)
    # If tracing fails, still execute the block with a no-op span
    # This ensures business logic runs even if telemetry breaks
    yield(NoOpSpan.new)
  end

  def self.current_span
    OpenTelemetry::Trace.current_span
  end
  private_class_method :current_span

  # Sanitize attribute values to ensure they're primitives (String, Integer, Float, Boolean)
  # OpenTelemetry requires attribute values to be primitives, not complex objects
  def self.sanitize_attribute_value(value)
    case value
    when String, Integer, Float, TrueClass, FalseClass, NilClass
      value
    when Array
      value.join(", ")
    else
      value.to_s
    end
  end
  private_class_method :sanitize_attribute_value

  # No-op span that safely ignores all method calls
  # Used as a fallback when tracing is disabled or fails
  class NoOpSpan
    def method_missing(_method_name, *_args, **_kwargs, &_block)
      # Silently ignore all method calls (set_attribute, add_event, etc.)
      nil
    end

    def respond_to_missing?(_method_name, _include_private = false)
      true
    end
  end
end
