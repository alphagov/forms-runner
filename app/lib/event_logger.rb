class EventLogger
  def self.log(tag, object)
    Rails.logger.info "[#{tag}] #{object.to_json}"
  end

  def self.log_form_event(context, request, event)
    item_to_log = {
      url: request&.url,
      method: request&.method,
      form: context.form_name,
    }

    log("form_#{event}", item_to_log)
  end

  def self.log_page_event(context, page, request, event, skipped_question: nil)
    item_to_log = {
      url: request&.url,
      method: request&.method,
      form: context.form_name,
      question_text: page.question.question_text,
    }

    item_to_log.merge!({ skipped_question: skipped_question.to_s }) unless skipped_question.nil?

    log(event.to_s, item_to_log)
  end
end
