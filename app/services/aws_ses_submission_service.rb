class AwsSesSubmissionService
  CSV_MAX_FILENAME_LENGTH = 100

  def initialize(current_context:, mailer_options:)
    @current_context = current_context
    @form = current_context.form
    @mailer_options = mailer_options
  end

  def submit
    if !@mailer_options.preview_mode && @form.submission_email.blank?
      raise StandardError, "Form id(#{@form.id}) is missing a submission email address"
    end

    if @form.submission_email.blank? && @mailer_options.preview_mode
      Rails.logger.info "Skipping sending submission email for preview submission, as the submission email address has not been set"
      return
    end

    if @form.submission_type == "email_with_csv"
      deliver_submission_email_with_csv_attachment
    else
      deliver_submission_email({})
    end
  end

private

  def deliver_submission_email_with_csv_attachment
    Tempfile.create do |file|
      write_submission_csv(file)

      files = { csv_filename => file }
      deliver_submission_email(files)
    end
  end

  def deliver_submission_email(files)
    mail = AwsSesFormSubmissionMailer.submission_email(answer_content:,
                                                       submission_email_address: @form.submission_email,
                                                       mailer_options: @mailer_options,
                                                       files:).deliver_now

    CurrentLoggingAttributes.submission_email_id = mail.message_id
  end

  def answer_content
    SesEmailFormatter.new.build_question_answers_section(@current_context)
  end

  def write_submission_csv(file)
    CsvGenerator.write_submission(
      current_context: @current_context,
      submission_reference: @mailer_options.submission_reference,
      timestamp: @mailer_options.timestamp,
      output_file_path: file.path,
    )
  end

  def csv_filename
    CsvGenerator.csv_filename(form_title: @mailer_options.title,
                              submission_reference: @mailer_options.submission_reference,
                              max_length: CSV_MAX_FILENAME_LENGTH)
  end
end
