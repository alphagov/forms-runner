class FileUploadFilenameGenerator
  FILE_MAX_FILENAME_LENGTH = 100

  class << self
    def sanitize(filename)
      filename.gsub(/[\/\\:*?"<>|]/, "")
    end

    def to_s3_submission(filename, suffix: "")
      extension = ::File.extname(filename)

      basename_max_length = FILE_MAX_FILENAME_LENGTH - extension.length - suffix.length

      basename = ::File.basename(sanitize(filename), extension).truncate(basename_max_length, omission: "")

      "#{basename}#{suffix}#{extension}"
    end

    def truncate_for_reference(filename)
      extension = ::File.extname(filename)

      basename_max_length = FILE_MAX_FILENAME_LENGTH - extension.length - ReferenceNumberService::REFERENCE_LENGTH

      basename = ::File.basename(sanitize(filename), extension).truncate(basename_max_length, omission: "")

      "#{basename}#{extension}"
    end

    def to_email_attachment(filename, submission_reference:, suffix: "")
      extension = ::File.extname(filename)

      submission_reference_with_underscore = "_#{submission_reference}"

      basename_max_length = FILE_MAX_FILENAME_LENGTH - submission_reference_with_underscore.length - extension.length - suffix.length

      basename = ::File.basename(sanitize(filename), extension).truncate(basename_max_length, omission: "")

      "#{basename}#{suffix}#{submission_reference_with_underscore}#{extension}"
    end
  end
end
