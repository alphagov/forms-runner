class ReceiveSubmissionDeliveriesJob < ApplicationJob
  include ReceiveSubmissionJobHelper

  queue_as :background

  SQS_QUEUE_NAME = "submission_email_ses_successful_deliveries_queue".freeze

private

  def process_ses_event(ses_event_type, submission)
    raise "Unexpected event type:#{ses_event_type}" unless ses_event_type == "Delivery"

    process_delivery(submission)
  end

  def process_delivery(submission)
    set_submission_logging_attributes(submission)

    submission.delivered!
    EventLogger.log_form_event("submission_delivered")
  end
end
