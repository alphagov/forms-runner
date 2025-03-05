class DeleteSubmissionsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    delete_submissions_updated_before_time = Settings.retain_submissions_for_seconds.seconds.ago
    submissions_to_delete = Submission.where(updated_at: ..delete_submissions_updated_before_time)
                            .where.not(mail_message_id: nil)

    submissions_to_delete.find_each { |submission| delete_submission_data(submission) }
  end

  def delete_submission_data(submission)
    files = submission.journey.completed_file_upload_questions
    files.each(&:delete_from_s3)
    submission.destroy!
    log_submission_deleted(submission)
  rescue StandardError => e
    Rails.logger.warn("Error deleting submission - #{e.class.name}: #{e.message}", {
      form_id: submission.form_id,
      submission_reference: submission.reference,
      job_id:,
    })
    Sentry.capture_exception(e)
  end

  def log_submission_deleted(submission)
    EventLogger.log_form_event("submission_deleted", {
      submission_reference: submission.reference,
      form_id: submission.form.id,
      form_name: submission.form.name,
      job_id:,
    })
  end
end
