class EventLogger
  def self.log_form_event(event, additional_context = {})
    log(additional_context.merge({ event: "form_#{event}" }))
  end

  def self.log_page_event(event, question_text, skipped_question)
    context = {}.tap do |h|
      h[:question_text] = question_text
      h[:event] = event.to_s
      h[:skipped_question] = skipped_question.to_s unless skipped_question.nil?
    end

    log(context)
  end

  def self.log(context)
    Rails.logger.info "Form event", context
  end
end
