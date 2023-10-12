class LogEventService
  def initialize(current_context, step, request, changing_answer, answers)
    @current_context = current_context
    @step = step
    @request = request
    @changing_answer = changing_answer
    @answers = answers
  end

  def self.log_form_start(context, request)
    EventLogger.log_form_event(context, request, "visit") # Logging to Splunk
    begin
      CloudWatchService.log_form_start(form_id: context.form.id) # Logging to CloudWatch
    rescue StandardError => e
      Sentry.capture_exception(e)
    end
  end

  def self.log_submit(context, request)
    EventLogger.log_form_event(context, request, "submission") # Logging to Splunk
    begin
      CloudWatchService.log_form_submission(form_id: context.form.id) # Logging to CloudWatch
    rescue StandardError => e
      Sentry.capture_exception(e)
    end
  end

  def log_page_save
    EventLogger.log_page_event(@current_context, @step, @request, log_event, skipped_question?)
  end

private

  def log_event
    page_optional = @step.question.is_optional? ? "optional" : "page"

    if @changing_answer
      "change_answer_#{page_optional}_save"
    elsif is_starting_form
      "first_#{page_optional}_save"
    else
      "#{page_optional}_save"
    end
  end

  def skipped_question?
    @step.question.is_optional? ? @answers.each_value.map.none?(&:present?) : nil
  end

  def is_starting_form
    @current_context.form.start_page == @step.id
  end
end
