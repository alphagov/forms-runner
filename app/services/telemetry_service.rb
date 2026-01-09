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

    current_span.set_attributes(attrs.compact.transform_keys(&:to_s))
  rescue StandardError => e
    Sentry.capture_exception(e) if defined?(Sentry)
  end

  # Set question-level attributes on page requests
  # Call from PageController to add question context to all page spans
  def self.set_question_attributes(step, form)
    return unless defined?(OpenTelemetry)

    current_span.set_attributes({
      "question.type" => step.question.class.name,
      "question.id" => step.page_id,
      "question.text" => step.question_text,
      "question.answer_type" => step.page&.answer_type,
      "question.number" => step.page_number,
      "question.is_optional" => step.question.is_optional?,
      "question.is_repeatable" => step.repeatable?,
      "form.submission_type" => form.submission_type,
    }.compact)
  rescue StandardError => e
    Sentry.capture_exception(e) if defined?(Sentry)
  end

  def self.record_validation_failure(step)
    return unless defined?(OpenTelemetry)

    current_span.set_attributes({
      "validation.failed" => true,
      "validation.error_count" => step.question.errors.count,
      "validation.errors" => step.question.errors.full_messages.join(", "),
      "validation.error_attributes" => step.question.errors.attribute_names.map(&:to_s).join(", "),
    })
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
    return yield unless defined?(OpenTelemetry)

    tracer = OpenTelemetry.tracer_provider.tracer("forms-runner", version: "1.0")

    tracer.in_span(span_name, attributes: attributes, &block)
  rescue StandardError => e
    Sentry.capture_exception(e) if defined?(Sentry)
    yield # Still execute the block even if tracing fails
  end

  def self.current_span
    OpenTelemetry::Trace.current_span
  end
  private_class_method :current_span
end
