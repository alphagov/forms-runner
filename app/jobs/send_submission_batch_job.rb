class SendSubmissionBatchJob < ApplicationJob
  queue_as :submissions

  # this translates to approximately 4.5 hours of retrying in total
  TOTAL_ATTEMPTS = 10

  retry_on Aws::SESV2::Errors::ServiceError, wait: :polynomially_longer, attempts: TOTAL_ATTEMPTS

  def perform(delivery:)
    submissions = delivery.submissions

    if submissions.empty?
      raise StandardError, "No submissions found for delivery id: #{delivery.id} when running job: #{job_id}"
    end

    form = submissions.first.form
    mode = submissions.first.mode_object
    date = submissions.first.submission_time.to_date
    set_submission_batch_logging_attributes(form:, mode:)

    if form.submission_email.blank?
      if mode.preview?
        Rails.logger.info "Skipping sending batch for preview submissions, as the submission email address has not been set"
        return
      else
        raise StandardError, "Form id: #{form.id} is missing a submission email address"
      end
    end

    message_id = AwsSesSubmissionBatchService.new(submissions_query: submissions, form:, date:, mode:).send_batch

    delivery.update!(
      delivery_reference: message_id,
      last_attempt_at: Time.zone.now,
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
