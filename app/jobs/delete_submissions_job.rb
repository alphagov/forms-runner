class DeleteSubmissionsJob < ApplicationJob
  queue_as :background

  def perform(*_args)
    CloudWatchService.record_job_started_metric(self.class.name)
    CurrentJobLoggingAttributes.job_class = self.class.name
    CurrentJobLoggingAttributes.job_id = job_id

    delete_after_delivered_delay = Settings.submissions.delete_not_bounced_after_seconds.seconds.ago

    delivered_submissions_to_delete = Submission.delivered.where(delivered_at: ..delete_after_delivered_delay)

    delete_all_submissions_created_before_time = Settings.submissions.maximum_retention_seconds.seconds.ago
    submissions_past_max_retention = Submission
      .where(created_at: ..delete_all_submissions_created_before_time)

    delivered_submissions_to_delete.find_each { |submission| delete_submission_data(submission) }
    submissions_past_max_retention.find_each { |submission| delete_submission_data(submission) }
  end

  def delete_submission_data(submission)
    set_submission_logging_attributes(submission)

    files = submission.journey.completed_file_upload_questions
    files.each(&:delete_from_s3)
    submission.destroy!

    EventLogger.log_form_event("submission_deleted", { delivery_status: submission.status })
    CloudWatchService.record_submission_deleted_metric(submission.status)
  rescue StandardError => e
    Rails.logger.warn("Error deleting submission - #{e.class.name}: #{e.message}")
    Sentry.capture_exception(e)
  ensure
    CurrentJobLoggingAttributes.reset
  end
end
