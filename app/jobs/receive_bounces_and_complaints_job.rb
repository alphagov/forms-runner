class ReceiveBouncesAndComplaintsJob < ApplicationJob
  require "aws-sdk-sqs"
  require "aws-sdk-sts"

  queue_as :default

  REGION = "eu-west-2".freeze
  QUEUE_NAME = "submission_email_ses_bounces_and_complaints_queue".freeze
  MAX_NUMBER_OF_MESSAGES = 10
  POLLING_PERIOD = 20

  # TODO: do we want to try to surface any details from the bounces to help with support?
  def perform
    # receive messages from the SQS queue
    # extract the message ids
    # retain the submissions and S3 objects
    # alert (separately or in aggregate?)
    # delete the messages from the SQS queue

    sts_client = Aws::STS::Client.new(region: REGION)
    queue_url = "https://sqs.#{REGION}.amazonaws.com/#{sts_client.get_caller_identity.account}/#{QUEUE_NAME}"
    sqs_client = Aws::SQS::Client.new(region: REGION)

    messages = receive_messages(sqs_client, queue_url)

    process_messages(sqs_client, queue_url, messages)
  end

private

  def receive_messages(sqs_client, queue_url)
    response = sqs_client.receive_message(
      queue_url: queue_url,
      max_number_of_messages: MAX_NUMBER_OF_MESSAGES,
      wait_time_seconds: POLLING_PERIOD, # Any value > 0 enables long polling
    )

    Rails.logger.info("Received #{response.messages.length} messages - #{self.class.name}:", {
      job_id:,
    })

    response.messages
  rescue StandardError => e
    Rails.logger.warn("Error receiving SQS messages - #{e.class.name}: #{e.message}", {
      job_id:,
    })
    Sentry.capture_exception(e)
  end

  def delete_message(sqs_client, queue_url, receipt_handle)
    sqs_client.delete_message(
      queue_url: queue_url,
      receipt_handle: receipt_handle,
    )

    Rails.logger.info("Message deleted successfully - #{self.class.name}:", {
      job_id:,
      receipt_handle:,
    })
  rescue StandardError => e
    Rails.logger.warn("Error deleting SQS message - #{e.class.name}: #{e.message}", {
      job_id:,
      receipt_handle:,
    })
    Sentry.capture_exception(e)
  end

  def process_bounces(ses_message_id)
    submission = Submission.find_by(mail_message_id: ses_message_id)

    # TODO: update retention of S3 objects
    # files = submission.journey.completed_file_upload_questions
    submission.update!(mail_status: "bounced")

    Rails.logger.info("Updated submission mail status to bounced - #{self.class.name}:", {
      form_id: submission.form_id,
      submission_reference: submission.reference,
      job_id:,
    })

    Sentry.capture_message("Updated submission mail status to bounced - #{self.class.name}:", {
      form_id: submission.form_id,
      submission_reference: submission.reference,
      job_id:,
    })
  rescue StandardError => e
    Rails.logger.warn("Error updating submission mail status - #{e.class.name}: #{e.message}", {
      job_id:,
    })
    Sentry.capture_exception(e)
  end

  def process_complaints(ses_message_id)
    #   submission = Submission.find_by(mail_message_id: ses_message_id)

    #   # TODO: update retention of S3 objects
    #   # files = submission.journey.completed_file_upload_questions
    #   submission.update!(mail_status: "bounced")

    #   Rails.logger.info("Updated submission mail status to bounced - #{self.class.name}:", {
    #     form_id: submission.form_id,
    #     submission_reference: submission.reference,
    #     job_id:,
    #   })
    # rescue StandardError => e
    #   Rails.logger.warn("Error updating submission mail status - #{e.class.name}: #{e.message}", {
    #     job_id:,
    #   })
    #   Sentry.capture_exception(e)
  end

  def process_messages(sqs_client, queue_url, messages)
    messages.each do |message|
      receipt_handle = message.receipt_handle
      sns_message = JSON.parse(message.body)
      ses_message = JSON.parse(sns_message["Message"])
      ses_message_id = ses_message["mail"]["messageId"]
      ses_notification_type = ses_message["notificationType"]

      process_bounces(ses_message_id) if ses_notification_type == "Bounce"
      process_complaints(ses_message_id) if ses_notification_type == "Complaint"

      delete_message(sqs_client, queue_url, receipt_handle)
    end
  end
end
