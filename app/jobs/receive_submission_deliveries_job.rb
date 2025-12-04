class ReceiveSubmissionDeliveriesJob < ApplicationJob
  queue_as :background

  SQS_QUEUE_NAME = "submission_email_ses_successful_deliveries_queue".freeze

  def perform
    CloudWatchService.record_job_started_metric(self.class.name)
    CurrentJobLoggingAttributes.job_class = self.class.name
    CurrentJobLoggingAttributes.job_id = job_id

    poller = AwsSesMessagePoller.new(
      queue_name: SQS_QUEUE_NAME,
      job_class_name: self.class.name,
      job_id: job_id,
    )

    poller.poll do |submission, ses_message|
      ses_event_type = ses_message["eventType"]

      raise "Unexpected event type:#{ses_event_type}" unless ses_event_type == "Delivery"

      delivery_time = Time.zone.parse(ses_message["delivery"]["timestamp"])
      process_delivery(submission, delivered_at: delivery_time)

      submission_duration_ms = ((delivery_time - submission.created_at) * 1000).round
      CloudWatchService.record_submission_delivery_latency_metric(submission_duration_ms, "Email")
    end
  end

private

  def process_delivery(submission, delivered_at:)
    set_submission_logging_attributes(submission)

    # Don't process delivery if already bounced. Bounces can occur asynchronously
    # and out of order from the initial delivery notification.
    # https://docs.aws.amazon.com/ses/latest/dg/send-email-concepts-deliverability.html
    unless submission.bounced?
      submission.update!(delivered_at: delivered_at, delivery_status: :delivered)
    end

    EventLogger.log_form_event("submission_delivered")
  end
end
