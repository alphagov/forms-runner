class AwsSesSubmissionBatchService
  def initialize(submissions_query:, form:, mode:)
    @submissions_query = submissions_query
    @form = form
    @mode = mode
  end

  def send_daily_batch(date:)
    files = {}

    csvs = CsvGenerator.generate_batched_submissions(submissions_query: @submissions_query, is_s3_submission: false)
    csvs.each.with_index(1) do |csv, index|
      csv_version = csvs.size > 1 ? index : nil
      filename = SubmissionFilenameGenerator.batch_csv_filename(form_name: @form.name, date:, mode: @mode, form_version: csv_version)
      files[filename] = csv
    end

    mail = AwsSesSubmissionBatchMailer.batch_submission_email(form: @form, date:, mode: @mode, files:).deliver_now

    CurrentJobLoggingAttributes.delivery_reference = mail.message_id
    mail.message_id
  end
end
