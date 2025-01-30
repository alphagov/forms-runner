require "rails_helper"

RSpec.describe Question::FileUploadS3Service do
  subject(:service) { described_class.new }

  let(:key) { Faker::Alphanumeric.alphanumeric }
  let(:bucket) { "an-s3-bucket" }
  let(:mock_s3_client) { Aws::S3::Client.new(stub_responses: true) }

  before do
    allow(Settings.aws).to receive(:file_upload_s3_bucket_name).and_return(bucket)
    allow(Aws::S3::Client).to receive(:new).and_return(mock_s3_client)
  end

  describe "#upload_to_s3" do
    context "when a file was selected" do
      let(:tempfile) { Tempfile.new(%w[temp-file .png]) }

      after do
        tempfile.unlink
      end

      before do
        allow(mock_s3_client).to receive(:put_object)
      end

      it "puts object to S3" do
        expect(mock_s3_client).to receive(:put_object).with(
          {
            body: tempfile,
            bucket: bucket,
            key:,
          },
        )
        service.upload_to_s3(tempfile, key)
      end
    end
  end

  describe "#file_from_s3" do
    let(:get_object_output) { instance_double(Aws::S3::Types::GetObjectOutput) }
    let(:tempfile) { Tempfile.new(%w[temp-file .png]) }
    let(:file_content) { Faker::Lorem.sentence }

    before do
      File.write(tempfile, file_content)

      allow(mock_s3_client).to receive(:get_object).and_return(get_object_output)
      allow(get_object_output).to receive(:body).and_return(tempfile)
    end

    after do
      tempfile.unlink
    end

    it("reads file contents from S3") do
      expect(service.file_from_s3(key)).to eq(file_content)
    end
  end

  describe "#delete_from_s3" do
    before do
      allow(mock_s3_client).to receive(:delete_object)
    end

    it("calls S3 to delete the file") do
      expect(mock_s3_client).to receive(:delete_object).with(
        {
          bucket:,
          key:,
        },
      )
      service.delete_from_s3(key)
    end
  end
end
