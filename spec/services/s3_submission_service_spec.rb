require "rails_helper"

RSpec.describe S3SubmissionService do
  subject(:service) do
    described_class.new(journey:, form:, timestamp:, submission_reference:, is_preview:)
  end

  let(:file_body) { "some body/n" }
  let(:form) do
    build(:form,
          id: 42,
          s3_bucket_name:,
          s3_bucket_aws_account_id:,
          s3_bucket_region:)
  end
  let(:s3_bucket_name) { "a-bucket" }
  let(:s3_bucket_aws_account_id) { "23423423423423" }
  let(:s3_bucket_region) { "eu-west-1" }
  let(:submission_reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }
  let(:timestamp) do
    Time.use_zone("London") { Time.zone.local(2022, 9, 14, 8, 24, 34) }
  end
  let(:all_steps) { [step] }
  let(:journey) { instance_double(Flow::Journey, completed_steps: all_steps, all_steps:) }
  let(:step) { build :step }
  let(:is_preview) { false }

  describe "#upload_submission_csv_to_s3" do
    let(:mock_credentials) { { foo: "bar" } }
    let(:mock_sts_client) { Aws::STS::Client.new(stub_responses: true) }
    let(:mock_s3_client) { Aws::S3::Client.new(stub_responses: true) }
    let(:role_arn) { "arn:aws:iam::11111111111:role/test-role" }

    context "when the form is configured correctly with S3 bucket details" do
      before do
        allow(CsvGenerator).to receive(:write_submission) do |args|
          File.write(args[:output_file_path], file_body)
        end
        allow(Aws::AssumeRoleCredentials).to receive(:new).and_return(mock_credentials)
        allow(Aws::STS::Client).to receive(:new).and_return(mock_sts_client)
        allow(Aws::S3::Client).to receive(:new).and_return(mock_s3_client)
        allow(mock_s3_client).to receive(:put_object)
        allow(Settings.aws).to receive(:s3_submission_iam_role_arn).and_return(role_arn)

        service.submit
      end

      it "writes a CSV file" do
        expect(CsvGenerator).to have_received(:write_submission)
          .with(all_steps:,
                submission_reference:,
                timestamp:,
                output_file_path: an_instance_of(String))
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
        expected_timestamp = "20220914T072434Z"
        expected_key_name = "form_submissions/#{form.id}/#{expected_timestamp}_#{submission_reference}/form_submission.csv"
        expect(mock_s3_client).to have_received(:put_object).with(
          body: file_body,
          bucket: s3_bucket_name,
          expected_bucket_owner: s3_bucket_aws_account_id,
          key: expected_key_name,
        )
      end

      context "when a preview is being submitted" do
        let(:is_preview) { true }

        it "calls put_object with a key starting with 'test_form_submissions/'" do
          expected_timestamp = "20220914T072434Z"
          expected_key_name = "test_form_submissions/#{form.id}/#{expected_timestamp}_#{submission_reference}/form_submission.csv"
          expect(mock_s3_client).to have_received(:put_object).with(
            body: file_body,
            bucket: s3_bucket_name,
            expected_bucket_owner: s3_bucket_aws_account_id,
            key: expected_key_name,
          )
        end
      end
    end

    context "when the form's s3_bucket_name is nil" do
      let(:s3_bucket_name) { nil }

      it "raises an error" do
        expect { service.submit }.to raise_error("S3 bucket name is not set on the form")
      end
    end

    context "when the form's s3_bucket_aws_account_id is nil" do
      let(:s3_bucket_aws_account_id) { nil }

      it "raises an error" do
        expect { service.submit }.to raise_error("S3 bucket account ID is not set on the form")
      end
    end

    context "when the form's s3_bucket_region is nil" do
      let(:s3_bucket_region) { nil }

      it "raises an error" do
        expect { service.submit }.to raise_error("S3 bucket region is not set on the form")
      end
    end
  end
end
