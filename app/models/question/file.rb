module Question
  class File < Question::QuestionBase
    include Question::File::VirusScan

    attribute :file
    attribute :original_filename
    attribute :uploaded_file_key
    attribute :filename_suffix, default: ""
    validates :file, presence: true, unless: :is_optional?
    validate :validate_file_size
    validate :validate_file_extension

    FILE_UPLOAD_MAX_SIZE_IN_MB = 7
    FILE_TYPES = [
      "text/csv",
      "image/jpeg",
      "image/png",
      "application/rtf",
      "text/plain",
      "application/pdf",
      "application/json",
      # .xlsx:
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      # .doc:
      "application/msword",
      # .docx:
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      # .odt:
      "application/vnd.oasis.opendocument.text",
    ].freeze
    FILE_MAX_FILENAME_LENGTH = 100

    def show_answer
      original_filename
    end

    def show_answer_in_email
      return nil if original_filename.blank?

      I18n.t("mailer.submission.file_attached", filename: name_with_filename_suffix)
    end

    def show_answer_in_csv
      return Hash[question_text, nil] if original_filename.blank?

      { question_text => name_with_filename_suffix }
    end

    def name_with_filename_suffix
      extension = ::File.extname(original_filename)

      base_name_max_length = FILE_MAX_FILENAME_LENGTH - extension.length - filename_suffix.length

      base_name = ::File.basename(original_filename, extension).truncate(base_name_max_length, omission: "")

      "#{base_name}#{filename_suffix}#{extension}"
    end

    def before_save
      if file.blank?
        # set to a blank string so that we serialize the answer correctly when an optional question isn't answered
        self.original_filename = ""
        return
      end

      tempfile = file.tempfile
      key = file_upload_s3_key(tempfile)
      FileUploadS3Service.new.upload_to_s3(tempfile, key)

      FileUploadLogger.log_s3_operation(key, "Uploaded file to S3 for file upload question", {
        file_size_in_bytes: file.size,
        file_type: file.content_type,
      })

      check_scan_result(key)

      self.original_filename = file.original_filename
      self.uploaded_file_key = key

      # we don't want to store the file itself on the session
      self.file = nil
    end

    def file_from_s3
      FileUploadS3Service.new.file_from_s3(uploaded_file_key)
    end

    def delete_from_s3
      FileUploadS3Service.new.delete_from_s3(uploaded_file_key)
    end

    def file_uploaded?
      uploaded_file_key.present?
    end

    def question_text_for_check_your_answers
      return question_text_with_optional_suffix if page_heading.blank?

      caption = tag.span(page_heading, class: %w[govuk-caption-m govuk-!-margin-bottom-1])
      [caption, question_text_with_optional_suffix].join(" ")
    end

  private

    def validate_file_size
      if file.present? && file.size > FILE_UPLOAD_MAX_SIZE_IN_MB.megabytes
        Rails.logger.info("File upload question validation failed: file too big", {
          file_size_in_bytes: file.size,
          file_type: file.content_type,
        })
        errors.add(:file, :too_big)
      end
    end

    def validate_file_extension
      if file.present? && FILE_TYPES.exclude?(file.content_type)
        Rails.logger.info("File upload question validation failed: disallowed file type", {
          file_size_in_bytes: file.size,
          file_type: file.content_type,
        })
        errors.add(:file, :disallowed_type)
      end
    end

    def file_upload_s3_key(file)
      uuid = SecureRandom.uuid
      extension = ::File.extname(file.path)
      "#{uuid}#{extension}"
    end
  end
end
