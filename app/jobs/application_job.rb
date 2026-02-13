class ApplicationJob < ActiveJob::Base
  def set_submission_logging_attributes(submission)
    CurrentJobLoggingAttributes.job_class = self.class.name
    CurrentJobLoggingAttributes.job_id = job_id
    CurrentJobLoggingAttributes.form_id = submission.form.id
    CurrentJobLoggingAttributes.form_name = submission.form.name
    CurrentJobLoggingAttributes.submission_reference = submission.reference
    CurrentJobLoggingAttributes.preview = submission.preview?
  end

  def set_submission_batch_logging_attributes(form:, mode:)
    CurrentJobLoggingAttributes.job_class = self.class.name
    CurrentJobLoggingAttributes.job_id = job_id
    CurrentJobLoggingAttributes.form_id = form.id
    CurrentJobLoggingAttributes.form_name = form.name
    CurrentJobLoggingAttributes.preview = mode.preview?
  end
end
