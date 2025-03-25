class CurrentJobLoggingAttributes < ActiveSupport::CurrentAttributes
  attribute :job_id, :form_id, :form_name, :submission_reference, :mail_message_id, :sqs_message_id

  def as_hash
    {
      job_id:,
      form_id:,
      form_name:,
      submission_reference:,
      mail_message_id:,
      sqs_message_id:,
    }.compact_blank
  end
end
