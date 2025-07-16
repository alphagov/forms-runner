class S3SubmissionJob < ApplicationJob
  queue_as :submissions

  def perform(submission)
    return if submission.delivery_status == "delivered"

    submission.update!(
      mail_message_id: message_id,
      delivery_status: :pending,
      last_delivery_attempt: Time.zone.now,
      failed_at: nil,
      delivered_at: nil,
    )

    S3SubmissionService.new(submission:).submit
  end
end
