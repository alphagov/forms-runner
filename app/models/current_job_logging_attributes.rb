class CurrentJobLoggingAttributes < ActiveSupport::CurrentAttributes
  attribute :job_id, :form_id, :form_name, :submission_reference, :mail_message_id, :sqs_message_id, :sns_message_timestamp

  def as_hash
    {
      job_id:,
      form_id:,
      form_name:,
      submission_reference:,
      mail_message_id:,
      sqs_message_id:,
      sns_message_timestamp:,
    }.compact_blank
  end
end
