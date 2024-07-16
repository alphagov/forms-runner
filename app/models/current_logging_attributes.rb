class CurrentLoggingAttributes < ActiveSupport::CurrentAttributes
  attribute :host, :request_id, :form_id, :form_name, :page_id, :page_slug, :session_id_hash, :trace_id,
            :question_number, :submission_reference, :submission_email_reference, :submission_email_id,
            :confirmation_email_reference, :confirmation_email_id, :rescued_exception, :rescued_exception_trace

  def as_hash
    {
      host:,
      request_id:,
      form_id:,
      form_name:,
      page_id:,
      page_slug:,
      session_id_hash:,
      trace_id:,
      question_number:,
      submission_reference:,
      notification_references: {
        confirmation_email_reference:,
        submission_email_reference:,
      }.compact,
      notification_ids: {
        confirmation_email_id:,
        submission_email_id:,
      }.compact,
      rescued_exception:,
      rescued_exception_trace:,
    }.compact_blank
  end
end
