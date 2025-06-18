class DeleteSubmissionsJob < ApplicationJob
  queue_as :background

  def perform(*_args)
    CloudWatchService.record_job_started_metric(self.class.name)
    CurrentJobLoggingAttributes.job_class = self.class.name
    CurrentJobLoggingAttributes.job_id = job_id

    delete_submissions_sent_before_time = Settings.retain_submissions_for_seconds.seconds.ago
    submissions_to_delete = Submission.where(sent_at: ..delete_submissions_sent_before_time)
                                      .not_bounced

    submissions_to_delete.find_each { |submission| delete_submission_data(submission) }
  end

  def delete_submission_data(submission)
    set_submission_logging_attributes(submission)

    files = submission.journey.completed_file_upload_questions
    files.each(&:delete_from_s3)
    submission.destroy!

    EventLogger.log_form_event("submission_deleted")
  rescue StandardError => e
    Rails.logger.warn("Error deleting submission - #{e.class.name}: #{e.message}")
    Sentry.capture_exception(e)
  ensure
    CurrentJobLoggingAttributes.reset
  end
end
