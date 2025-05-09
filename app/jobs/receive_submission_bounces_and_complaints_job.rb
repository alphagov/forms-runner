class ReceiveSubmissionBouncesAndComplaintsJob < ApplicationJob
  self.queue_adapter = :sqs

  def perform(message)
    sqs_message_id = message["message_id"]
    CurrentJobLoggingAttributes.sqs_message_id = sqs_message_id

    process_message(message["body"])
  end

private

  def process_message(ses_message)
    ses_message_id = ses_message["Message"]["mail"]["messageId"]
    CurrentJobLoggingAttributes.mail_message_id = ses_message_id

    ses_event_type = ses_message["Message"]["eventType"]

    submission = Submission.find_by!(mail_message_id: ses_message_id)
    set_submission_logging_attributes(submission)

    case ses_event_type
    when "Bounce"
      submission.bounced!
      EventLogger.log_form_event("submission_bounced")
    when "Complaint"
      submission.complained!
      EventLogger.log_form_event("submission_complained")
    else
      raise "Unexpected event type:#{ses_event_type}"
    end
  end
end
