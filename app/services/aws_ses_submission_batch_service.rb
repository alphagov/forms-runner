class AwsSesSubmissionBatchService
  def initialize(submissions:, form:, date:, mode:)
    @submissions = submissions
    @form = form
    @date = date
    @mode = mode
  end

  def send_batch
    if @form.submission_email.blank?
      if @mode.preview?
        Rails.logger.info "Skipping sending batch for preview submissions, as the submission email address has not been set"
        return
      else
        raise StandardError, "Form id: #{@form.id} is missing a submission email address"
      end
    end

    deliver_batch_email
  end

private

  def deliver_batch_email
    files = {}

    submissions_by_version = Submission.group_by_form_version(@submissions)
    submissions_by_version.each_value.with_index(1) do |submissions, version_number|
      form_version = submissions_by_version.size > 1 ? version_number : nil
      filename = SubmissionFilenameGenerator.batch_csv_filename(form_name: @form.name, date: @date, mode: @mode, form_version: form_version)
      files[filename] = CsvGenerator.generate_batched_submissions(submissions: submissions, is_s3_submission: false)
    end

    mail = AwsSesSubmissionBatchMailer.batch_submission_email(form: @form, date: @date, mode: @mode, files:).deliver_now

    CurrentJobLoggingAttributes.delivery_reference = mail.message_id
    mail.message_id
  end
end
