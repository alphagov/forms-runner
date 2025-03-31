class CurrentRequestLoggingAttributes < ActiveSupport::CurrentAttributes
  attribute :request_host, :request_id, :form_id, :form_name, :preview, :page_id, :page_slug, :session_id_hash, :trace_id,
            :question_number, :submission_reference, :submission_email_reference, :submission_email_id,
            :confirmation_email_reference, :confirmation_email_id, :rescued_exception, :rescued_exception_trace

  def as_hash
    {
      request_host:,
      request_id:,
      form_id:,
      form_name:,
      preview: preview.to_s,
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
