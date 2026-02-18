class AwsSesSubmissionBatchService
  def initialize(submissions_query:, form:, date:, mode:)
    @submissions_query = submissions_query
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

    csvs = CsvGenerator.generate_batched_submissions(submissions_query: @submissions_query, is_s3_submission: false)
    csvs.each.with_index(1) do |csv, index|
      csv_version = csvs.size > 1 ? index : nil
      filename = SubmissionFilenameGenerator.batch_csv_filename(form_name: @form.name, date: @date, mode: @mode, form_version: csv_version)
      files[filename] = csv
    end

    mail = AwsSesSubmissionBatchMailer.batch_submission_email(form: @form, date: @date, mode: @mode, files:).deliver_now

    CurrentJobLoggingAttributes.delivery_reference = mail.message_id
    mail.message_id
  end
end
