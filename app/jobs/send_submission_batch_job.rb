class SendSubmissionBatchJob < ApplicationJob
  queue_as :submissions

  # this translates to approximately 4.5 hours of retrying in total
  TOTAL_ATTEMPTS = 10

  retry_on Aws::SESV2::Errors::ServiceError, wait: :polynomially_longer, attempts: TOTAL_ATTEMPTS

  def perform(form_id:, mode_string:, date:, delivery:)
    submissions = Submission.for_daily_batch(form_id, date, mode_string)

    if submissions.empty?
      Rails.logger.info("No submissions to batch for form_id: #{form_id}, mode: #{mode_string}, date: #{date}")
      return
    end

    form = submissions.first.form
    mode = Mode.new(mode_string)
    set_submission_batch_logging_attributes(form:, mode:)

    message_id = AwsSesSubmissionBatchService.new(submissions:, form:, date:, mode:).send_batch

    delivery.update!(
      delivery_reference: message_id,
      last_attempt_at: Time.zone.now,
      submissions: submissions,
    )

    EventLogger.log_form_event("daily_batch_email_sent", {
      mode:,
      batch_date: date,
      number_of_submissions: submissions.count,
    })

    submissions.each do |submission|
      EventLogger.log_form_event("included_in_daily_batch_email", {
        submission_reference: submission.reference,
        batch_date: date,
      })
    end
  end
end
