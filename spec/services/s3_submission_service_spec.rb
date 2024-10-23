require "rails_helper"

RSpec.describe S3SubmissionService do
  subject(:service) do
    described_class.new(file_path: test_file.path, form_id:, s3_bucket_name:,
                        s3_bucket_aws_account_id:, s3_bucket_region:, timestamp:, submission_reference:)
  end

  let(:test_file) do
    temp = Tempfile.new
    temp << file_body
    temp.flush
    temp
  end
  let(:file_body) { "some body/n" }
  let(:form_id) { 42 }
  let(:s3_bucket_name) { "a-bucket" }
  let(:s3_bucket_aws_account_id) { "23423423423423" }
  let(:s3_bucket_region) { "eu-west-1" }
  let(:submission_reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }
  let(:timestamp) do
    Time.use_zone("London") { Time.zone.local(2022, 9, 14, 8, 0o0, 0o0) }
  end

  after do
    test_file.unlink
  end

  describe "initialize" do
    context "when s3_bucket_name is nil" do
      it "raises an ArgumentException" do
        expect {
          described_class.new(file_path: test_file.path, form_id:, s3_bucket_name: nil,
                              s3_bucket_aws_account_id:, s3_bucket_region:, timestamp:, submission_reference:)
        }
          .to raise_error(ArgumentError, "s3_bucket_name cannot be nil")
      end
    end

    context "when s3_bucket_aws_account_id is nil" do
      it "raises an ArgumentException" do
        expect {
          described_class.new(file_path: test_file.path, form_id:, s3_bucket_name:,
                              s3_bucket_aws_account_id: nil, s3_bucket_region:, timestamp:, submission_reference:)
        }
          .to raise_error(ArgumentError, "s3_bucket_aws_account_id cannot be nil")
      end
    end

    context "when s3_bucket_region is nil" do
      it "raises an ArgumentException" do
        expect {
          described_class.new(file_path: test_file.path, form_id:, s3_bucket_name:,
                              s3_bucket_aws_account_id:, s3_bucket_region: nil, timestamp:, submission_reference:)
        }
          .to raise_error(ArgumentError, "s3_bucket_region cannot be nil")
      end
    end
  end

  describe "#upload_file_to_s3" do
    let(:mock_credentials) { { foo: "bar" } }
    let(:mock_sts_client) { Aws::STS::Client.new(stub_responses: true) }
    let(:mock_s3_client) { Aws::S3::Client.new(stub_responses: true) }
    let(:role_arn) { "arn:aws:iam::11111111111:role/test-role" }

    before do
      allow(Aws::AssumeRoleCredentials).to receive(:new).and_return(mock_credentials)
      allow(Aws::STS::Client).to receive(:new).and_return(mock_sts_client)
      allow(Aws::S3::Client).to receive(:new).and_return(mock_s3_client)
      allow(mock_s3_client).to receive(:put_object)
      allow(Settings.aws_s3_submissions).to receive(:iam_role_arn).and_return(role_arn)

      service.upload_file_to_s3
    end

    it "calls AWS to assume the role to upload to S3" do
      expected_session_name = "forms-runner-#{submission_reference}"
      expect(Aws::AssumeRoleCredentials).to have_received(:new).with(client: mock_sts_client, role_arn:,
                                                                     role_session_name: expected_session_name)
    end

    it "creates an S3 client with the credentials for the assumed role" do
      expect(Aws::S3::Client).to have_received(:new).with(region: s3_bucket_region, credentials: mock_credentials)
    end

    it "calls put_object" do
      expected_key_name = "form_submission/#{form_id}_#{timestamp}_#{submission_reference}.csv"
      expect(mock_s3_client).to have_received(:put_object).with(
        body: file_body,
        bucket: s3_bucket_name,
        expected_bucket_owner: s3_bucket_aws_account_id,
        key: expected_key_name,
      )
    end
  end
end
