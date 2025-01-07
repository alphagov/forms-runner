module Question
  class File < Question::QuestionBase
    attribute :file
    attribute :original_filename
    attribute :uploaded_file_key

    def show_answer
      original_filename
    end

    def before_save
      tempfile = file.tempfile
      key = file_upload_s3_key(tempfile)
      upload_to_s3(tempfile, key)

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
