class SubmissionS3Service
  def upload_file_to_s3(file_path, form_id, timestamp, submission_reference)
    s3 = Aws::S3::Client.new(
      region: "eu-west-2",
      credentials: assume_role(submission_reference),
    )
    key_name = key_name(form_id, timestamp, submission_reference)
    s3.put_object({
      body: File.read(file_path),
      bucket: Settings.aws_s3_submissions.bucket_name,
      key: key_name,
    })
    Rails.logger.info("Uploaded submission to S3", { key_name: })
  end

private

  def assume_role(submission_reference)
    credentials = Aws::AssumeRoleCredentials.new(
      client: Aws::STS::Client.new,
      role_arn: Settings.aws_s3_submissions.iam_role_arn,
      role_session_name: "forms-runner-#{submission_reference}",
    )
    Rails.logger.info "Assumed S3 role"
    credentials
  end

  def key_name(form_id, timestamp, submission_reference)
    "form_submission/#{form_id}/#{timestamp}_#{submission_reference}.csv"
  end
end
