class AwsSesSubmissionService
  CSV_MAX_FILENAME_LENGTH = 100

  def initialize(journey:, form:, mailer_options:)
    @journey = journey
    @form = form
    @mailer_options = mailer_options
  end

  def submit
    if !@mailer_options.is_preview && @form.submission_email.blank?
      raise StandardError, "Form id(#{@form.id}) is missing a submission email address"
    end

    if @form.submission_email.blank? && @mailer_options.is_preview
      Rails.logger.info "Skipping sending submission email for preview submission, as the submission email address has not been set"
      return
    end

    files = uploaded_files_in_answers

    raise StandardError, "Number of files does not match number of completed file questions" unless files.count == @journey.completed_file_upload_questions.count

    if @form.submission_type == "email_with_csv"
      deliver_submission_email_with_csv_attachment(files)
    else
      deliver_submission_email(files)
    end
  end

private

  def deliver_submission_email_with_csv_attachment(files)
    Tempfile.create do |file|
      write_submission_csv(file)

      files = files.merge({ csv_filename => File.read(file.path) })
      deliver_submission_email(files, csv_filename)
    end
  end

  def deliver_submission_email(files, csv_filename = nil)
    mail = AwsSesFormSubmissionMailer.submission_email(answer_content_html:,
                                                       answer_content_plain_text:,
                                                       submission_email_address: @form.submission_email,
                                                       mailer_options: @mailer_options,
                                                       files:,
                                                       csv_filename:).deliver_now

    CurrentJobLoggingAttributes.mail_message_id = mail.message_id
    mail.message_id
  end

  def answer_content_html
    SesEmailFormatter.new.build_question_answers_section_html(@journey.completed_steps)
  end

  def answer_content_plain_text
    SesEmailFormatter.new.build_question_answers_section_plain_text(@journey.completed_steps)
  end

  def uploaded_files_in_answers
    @journey.completed_file_upload_questions
            .each { it.populate_email_filename(submission_reference: @mailer_options.submission_reference) }
            .map { |question| [question.email_filename, question.file_from_s3] }
            .to_h
  end

  def write_submission_csv(file)
    CsvGenerator.write_submission(
      all_steps: @journey.all_steps,
      submission_reference: @mailer_options.submission_reference,
      timestamp: @mailer_options.timestamp,
      output_file_path: file.path,
      is_s3_submission: false,
    )
  end

  def csv_filename
    CsvGenerator.csv_filename(form_title: @mailer_options.title,
                              submission_reference: @mailer_options.submission_reference,
                              max_length: CSV_MAX_FILENAME_LENGTH)
  end
end
