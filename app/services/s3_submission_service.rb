class S3SubmissionService
  def initialize(file_path:,
                 form_id:,
                 s3_bucket_name:,
                 s3_bucket_aws_account_id:,
                 s3_bucket_region:,
                 timestamp:,
                 submission_reference:)
    raise ArgumentError, "s3_bucket_name cannot be nil" if s3_bucket_name.nil?
    raise ArgumentError, "s3_bucket_aws_account_id cannot be nil" if s3_bucket_aws_account_id.nil?
    raise ArgumentError, "s3_bucket_region cannot be nil" if s3_bucket_region.nil?

    @file_path = file_path
    @form_id = form_id
    @bucket = s3_bucket_name
    @expected_bucket_owner = s3_bucket_aws_account_id
    @region = s3_bucket_region
    @timestamp = timestamp
    @submission_reference = submission_reference
  end

  def upload_file_to_s3
    s3 = Aws::S3::Client.new(
      region: @region,
      credentials: assume_role,
    )
    s3.put_object({
      body: File.read(@file_path),
      bucket: @bucket,
      expected_bucket_owner: @expected_bucket_owner,
      key: key_name,
    })
    Rails.logger.info("Uploaded submission to S3", { key_name: })
  end

private

  def assume_role
    role_session_name = "forms-runner-#{@submission_reference}"
    credentials = Aws::AssumeRoleCredentials.new(
      client: Aws::STS::Client.new,
      role_arn: Settings.aws_s3_submissions.iam_role_arn,
      role_session_name:,
    )
    Rails.logger.info "Assumed S3 role", { role_session_name: }
    credentials
  end

  def key_name
    "form_submission/#{@form_id}_#{@timestamp}_#{@submission_reference}.csv"
  end
end
