class LogEventService
  def initialize(current_context, step, request, changing_answer, answers)
    @current_context = current_context
    @step = step
    @request = request
    @changing_answer = changing_answer
    @answers = answers
  end

  def self.log_form_start(logging_context)
    EventLogger.log_form_event(logging_context, "visit") # Logging to Splunk
  end

  def self.log_submit(logging_context, context, requested_email_confirmation: false, preview: false)
    if preview
      EventLogger.log_form_event(logging_context, "preview_submission")
    else
      # Logging to Splunk
      EventLogger.log_form_event(logging_context, "submission")

      EventLogger.log_form_event(logging_context, "requested_email_confirmation") if requested_email_confirmation

      # Logging to CloudWatch
      begin
        CloudWatchService.log_form_submission(form_id: context.form.id)
      rescue StandardError => e
        Sentry.capture_exception(e)
      end
    end
  end

  def log_page_save(logging_context)
    EventLogger.log_page_event(logging_context, log_event, skipped_question?)
    if is_starting_form?
      begin
        CloudWatchService.log_form_start(form_id: @current_context.form.id) # Logging to CloudWatch
      rescue StandardError => e
        Sentry.capture_exception(e)
      end
    end
  end

private

  def log_event
    page_optional = @step.question.is_optional? ? "optional" : "page"

    if @changing_answer
      "change_answer_#{page_optional}_save"
    elsif is_starting_form?
      "first_#{page_optional}_save"
    else
      "#{page_optional}_save"
    end
  end

  def skipped_question?
    @step.question.is_optional? ? @answers.each_value.map.none?(&:present?) : nil
  end

  def is_starting_form?
    @current_context.form.start_page == @step.id
  end
end
