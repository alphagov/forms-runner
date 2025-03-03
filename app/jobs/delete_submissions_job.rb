class DeleteSubmissionsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    delete_submissions_updated_after_time = Settings.retain_submissions_for_seconds.seconds.ago
    submissions_to_delete = Submission.where(updated_at: delete_submissions_updated_after_time..)
                            .where.not(mail_message_id: nil)
                            .order(:updated_at)

    submissions_to_delete.find_each { |submission| delete_submission_data(submission) }
  end

  def delete_submission_data(submission)
    files = submission.journey.completed_file_upload_questions
    files.each(&:delete_from_s3)
    submission.destroy!
  rescue StandardError => e
    Rails.logger.error("Error deleting submission: #{e.class.name}: #{e.message}", {
      form_id: submission.form_id,
      submission_reference: submission.reference,
    })
  end
end
