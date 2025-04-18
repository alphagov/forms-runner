class ApplicationJob < ActiveJob::Base
  def set_submission_logging_attributes(submission)
    CurrentJobLoggingAttributes.job_id = job_id
    CurrentJobLoggingAttributes.form_id = submission.form.id
    CurrentJobLoggingAttributes.form_name = submission.form.name
    CurrentJobLoggingAttributes.submission_reference = submission.reference
  end
end
