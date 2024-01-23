class EventLogger
  def self.log(object)
    Rails.logger.info object.to_json
  end

  def self.log_form_event(logging_context, event)
    log (logging_context.merge({ event: "form_#{event}" }))
  end

  def self.log_page_event(logging_context, event, skipped_question)
    log (logging_context.tap do |h|
      h[:event] = event.to_s
      h[:skipped_question] = skipped_question.to_s unless skipped_question.nil?
    end)
  end
end
