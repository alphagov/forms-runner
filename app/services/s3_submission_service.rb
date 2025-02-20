class S3SubmissionService
  def initialize(journey:, form:,
                 timestamp:,
                 submission_reference:,
                 is_preview:)
    @journey = journey
    @form = form
    @timestamp = timestamp
    @submission_reference = submission_reference
    @is_preview = is_preview
  end

  def submit
    raise StandardError, "S3 bucket name is not set on the form" if @form.s3_bucket_name.nil?
    raise StandardError, "S3 bucket account ID is not set on the form" if @form.s3_bucket_aws_account_id.nil?
    raise StandardError, "S3 bucket region is not set on the form" if @form.s3_bucket_region.nil?

    # rubocop:disable Rails/SaveBang
    Tempfile.create do |file|
      write_submission_csv(file)
      upload_file_to_s3(file.path)
    end
    # rubocop:enable Rails/SaveBang
  end

private

  # we only need all_steps. Should we just pass this in, or are we missing something that needs completed_steps?
  def write_submission_csv(file)
    CsvGenerator.write_submission(
      all_steps: @journey.all_steps,
      submission_reference: @submission_reference,
      timestamp: @timestamp,
      output_file_path: file.path,
    )
  end

  def upload_file_to_s3(file_path)
    s3 = Aws::S3::Client.new(
      region: @form.s3_bucket_region,
      credentials: assume_role,
    )
    s3.put_object({
      body: File.read(file_path),
      bucket: @form.s3_bucket_name,
      expected_bucket_owner: @form.s3_bucket_aws_account_id,
      key: key_name,
    })
    Rails.logger.info("Uploaded submission to S3", { key_name: })
  end

  def assume_role
    role_session_name = "forms-runner-#{@submission_reference}"
    credentials = Aws::AssumeRoleCredentials.new(
      client: Aws::STS::Client.new,
      role_arn: Settings.aws.s3_submission_iam_role_arn,
      role_session_name:,
    )
    Rails.logger.info "Assumed S3 role", { role_session_name: }
    credentials
  end

  def key_name
    folder = @is_preview ? "test_form_submissions" : "form_submissions"
    formatted_timestamp = @timestamp.utc.strftime("%Y%m%dT%H%M%SZ")
    "#{folder}/#{@form.id}/#{formatted_timestamp}_#{@submission_reference}.csv"
  end
end
