class S3SubmissionService
  def initialize(journey:,
                 form:,
                 timestamp:,
                 submission_reference:,
                 is_preview:)
    @journey = journey
    @form = form
    @timestamp = timestamp
    @submission_reference = submission_reference
    @is_preview = is_preview
    @file_upload_bucket_name = Settings.aws.file_upload_s3_bucket_name
  end

  def submit
    raise StandardError, "S3 bucket name is not set on the form" if @form.s3_bucket_name.nil?
    raise StandardError, "S3 bucket account ID is not set on the form" if @form.s3_bucket_aws_account_id.nil?
    raise StandardError, "S3 bucket region is not set on the form" if @form.s3_bucket_region.nil?

    # We send the uploaded files before the submissions CSV so that processors can have automations run when the CSV
    # file arrives and the referenced files will already be present
    copy_uploaded_files_to_bucket

    # rubocop:disable Rails/SaveBang
    Tempfile.create do |file|
      write_submission_csv(file)
      upload_submission_csv_to_s3(file.path)
    end
    # rubocop:enable Rails/SaveBang

    delete_uploaded_files_from_our_bucket
  end

private

  def copy_uploaded_files_to_bucket
    @journey.completed_file_upload_questions.each(&method(:copy_file_to_bucket))
  end

  def copy_file_to_bucket(file)
    source_key = file.uploaded_file_key
    target_key = uploaded_file_target_key(file)
    s3_client.copy_object({
      bucket: @form.s3_bucket_name,
      expected_bucket_owner: @form.s3_bucket_aws_account_id,
      copy_source: "/#{@file_upload_bucket_name}/#{source_key}",
      key: target_key,
      tagging_directive: "REPLACE", # we don't want to copy tags
    })
    Rails.logger.info("Copied uploaded file to submission S3 bucket", {
      source_key:,
      target_key:,
    })
  end

  def delete_uploaded_files_from_our_bucket
    @journey.completed_file_upload_questions.each(&:delete_from_s3)
  end

  def write_submission_csv(file)
    CsvGenerator.write_submission(
      all_steps: @journey.all_steps,
      submission_reference: @submission_reference,
      timestamp: @timestamp,
      output_file_path: file.path,
      is_s3_submission: true,
    )
  end

  def upload_submission_csv_to_s3(file_path)
    key = csv_submission_key
    s3_client.put_object({
      body: File.read(file_path),
      bucket: @form.s3_bucket_name,
      expected_bucket_owner: @form.s3_bucket_aws_account_id,
      key: key,
    })
    Rails.logger.info("Uploaded submission to S3", { key: })

    submission_duration_ms = (Time.current - @timestamp).in_milliseconds.round
    CloudWatchService.record_submission_delivery_latency_metric(submission_duration_ms, "S3")
  end

  def s3_client
    @s3_client ||= Aws::S3::Client.new(
      region: @form.s3_bucket_region,
      credentials: assume_role,
    )
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

  def csv_submission_key
    generate_key("form_submission.csv")
  end

  def uploaded_file_target_key(file)
    generate_key(file.filename_for_s3_submission)
  end

  def generate_key(filename)
    folder = @is_preview ? "test_form_submissions" : "form_submissions"
    formatted_timestamp = @timestamp.utc.strftime("%Y%m%dT%H%M%SZ")
    "#{folder}/#{@form.id}/#{formatted_timestamp}_#{@submission_reference}/#{filename}"
  end
end
