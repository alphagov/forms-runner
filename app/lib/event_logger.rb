class EventLogger
  def self.log(object)
    Rails.logger.info object.to_json
  end

  def self.log_form_event(context, request, event)
    session_id_hash = SessionHasher.new(request).request_to_session_hash

    log({
      url: request&.url,
      method: request&.method,
      request_id: request&.request_id,
      session_id_hash:,
      form: context.form.name,
      form_id: context.form.id,
      event: "form_#{event}",
    })
  end

  def self.log_page_event(context, page, request, event, skipped_question)
    session_id_hash = SessionHasher.new(request).request_to_session_hash

    item_to_log = {
      url: request&.url,
      method: request&.method,
      form: context.form.name,
      question_text: page.question.question_text,
      question_number: page.page_number,
      request_id: request&.request_id,
      session_id_hash:,
      event: event.to_s,
    }

    item_to_log.merge!({ skipped_question: skipped_question.to_s }) unless skipped_question.nil?

    log(item_to_log)
  end
end
