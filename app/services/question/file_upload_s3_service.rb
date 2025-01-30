class Question::FileUploadS3Service
  def initialize
    @bucket = Settings.aws.file_upload_s3_bucket_name
    @s3 = Aws::S3::Client.new
  end

  def upload_to_s3(file, key)
    @s3.put_object({
      body: file,
      bucket: @bucket,
      key:,
    })
    key
  end

  def file_from_s3(key)
    @s3.get_object({
      bucket: @bucket,
      key:,
    }).body.read
  end

  def delete_from_s3(key)
    @s3.delete_object({
      bucket: @bucket,
      key:,
    })
  end
end
