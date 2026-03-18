class AwsSesSubmissionBatchService
  def initialize(submissions_query:, form:, mode:)
    @submissions_query = submissions_query
    @form = form
    @mode = mode
  end

  def send_daily_batch(date:)
    files = csv_attachments(date)

    mail = AwsSesSubmissionBatchMailer.daily_submission_batch_email(form: @form, date:, mode: @mode, files:).deliver_now

    CurrentJobLoggingAttributes.delivery_reference = mail.message_id
    mail.message_id
  end

  def send_weekly_batch(begin_date:, end_date:)
    files = csv_attachments(end_date)

    mail = AwsSesSubmissionBatchMailer.weekly_submission_batch_email(
      form: @form,
      begin_date:,
      end_date:,
      mode: @mode,
      files:,
    ).deliver_now

    CurrentJobLoggingAttributes.delivery_reference = mail.message_id
    mail.message_id
  end

private

  def csv_attachments(date_for_filename)
    files = {}

    csvs = CsvGenerator.generate_batched_submissions(submissions_query: @submissions_query, is_s3_submission: false)
    csvs.each.with_index(1) do |csv, index|
      csv_version = csvs.size > 1 ? index : nil
      filename = SubmissionFilenameGenerator.batch_csv_filename(
        form_name: @form.name,
        date: date_for_filename,
        mode: @mode,
        form_version: csv_version,
      )

      files[filename] = csv
    end

    files
  end
end
