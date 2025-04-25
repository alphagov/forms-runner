class ReceiveSubmissionBouncesAndComplaintsJob < ApplicationJob
  require "aws-sdk-sqs"
  require "aws-sdk-sts"

  queue_as :background

  REGION = "eu-west-2".freeze
  SQS_QUEUE_NAME = "submission_email_ses_bounces_and_complaints_queue".freeze
  MAX_NUMBER_OF_MESSAGES = 10
  POLLING_PERIOD = 20

  def perform
    CloudWatchService.log_job_started(self.class.name)
    CurrentJobLoggingAttributes.job_id = job_id

    sts_client = Aws::STS::Client.new(region: REGION)
    queue_url = "https://sqs.#{REGION}.amazonaws.com/#{sts_client.get_caller_identity.account}/#{SQS_QUEUE_NAME}"
    sqs_client = Aws::SQS::Client.new(region: REGION)

    loop do
      messages = receive_messages(sqs_client, queue_url)

      break if messages.empty?

      process_messages(sqs_client, queue_url, messages)
    end
  end

private

  def receive_messages(sqs_client, queue_url)
    response = sqs_client.receive_message(
      queue_url: queue_url,
      max_number_of_messages: MAX_NUMBER_OF_MESSAGES,
      wait_time_seconds: POLLING_PERIOD, # Any value > 0 enables long polling
    )

    Rails.logger.info("Received #{response.messages.length} messages - #{self.class.name}")

    response.messages
  end

  def process_messages(sqs_client, queue_url, messages)
    messages.each do |message|
      sqs_message_id = message.message_id
      CurrentJobLoggingAttributes.sqs_message_id = sqs_message_id

      receipt_handle = message.receipt_handle
      sns_message = JSON.parse(message.body)
      ses_message = JSON.parse(sns_message["Message"])
      ses_message_id = ses_message["mail"]["messageId"]
      CurrentJobLoggingAttributes.mail_message_id = ses_message_id

      ses_event_type = ses_message["eventType"]

      raise "Unexpected event type:#{ses_event_type}" unless %w[Bounce Complaint].include?(ses_event_type)

      submission = Submission.find_by!(mail_message_id: ses_message_id)

      process_bounce(submission) if ses_event_type == "Bounce"
      process_complaint(submission) if ses_event_type == "Complaint"

      sqs_client.delete_message(queue_url: queue_url, receipt_handle: receipt_handle)
    rescue StandardError => e
      Rails.logger.warn("Error processing message - #{e.class.name}: #{e.message}")
      Sentry.capture_exception(e)
    ensure
      CurrentJobLoggingAttributes.reset
    end
  end

  def process_bounce(submission)
    set_submission_logging_attributes(submission)

    submission.bounced!

    EventLogger.log_form_event("submission_bounced")

    Sentry.capture_message("Submission email bounced - #{self.class.name}:", extra: {
      form_id: submission.form_id,
      submission_reference: submission.reference,
      job_id:,
    })
  end

  def process_complaint(submission)
    set_submission_logging_attributes(submission)

    EventLogger.log_form_event("submission_complaint")
  end
end
