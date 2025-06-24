class CurrentJobLoggingAttributes < ActiveSupport::CurrentAttributes
  attribute :job_class, :job_id, :form_id, :form_name, :submission_reference, :preview, :mail_message_id, :sqs_message_id, :sns_message_timestamp

  def as_hash
    {
      job_class:,
      job_id:,
      form_id:,
      form_name:,
      submission_reference:,
      preview: preview.to_s,
      mail_message_id:,
      sqs_message_id:,
      sns_message_timestamp:,
    }.compact_blank
  end
end
