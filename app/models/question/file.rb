module Question
  class File < Question::QuestionBase
    attribute :file
    attribute :original_filename
    attribute :uploaded_file_key
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

    def show_answer
      original_filename
    end

    def before_save
      if file.blank?
        # set to a blank string so that we serialize the answer correctly when an optional question isn't answered
        self.original_filename = ""
        return
      end

      tempfile = file.tempfile
      key = file_upload_s3_key(tempfile)
      upload_to_s3(tempfile, key)
      Rails.logger.info("Uploaded file to S3 for file upload question", {
        file_size_in_bytes: file.size,
        file_type: file.content_type,
      })

      self.original_filename = file.original_filename
      self.uploaded_file_key = key

      # we don't want to store the file itself on the session
      self.file = nil
    end

    def file_from_s3
      s3 = Aws::S3::Client.new
      s3.get_object({
        bucket: Settings.aws.file_upload_s3_bucket_name,
        key: uploaded_file_key,
      }).body.read
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

    def upload_to_s3(file, key)
      s3 = Aws::S3::Client.new
      s3.put_object({
        body: file,
        bucket: Settings.aws.file_upload_s3_bucket_name,
        key:,
      })
      key
    end
  end
end
