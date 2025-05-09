class ReceiveSubmissionDeliveriesJob < ApplicationJob
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
    raise "Unexpected event type:#{ses_event_type}" unless ses_event_type == "Delivery"

    submission = Submission.find_by!(mail_message_id: ses_message_id)
    set_submission_logging_attributes(submission)
    submission.delivered!

    EventLogger.log_form_event("submission_delivered")
  end
end
