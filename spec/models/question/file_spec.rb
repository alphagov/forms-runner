require "rails_helper"

RSpec.describe Question::File, type: :model do
  subject(:question) { described_class.new({}, options) }

  let(:options) { { is_optional:, question_text: } }

  let(:is_optional) { false }
  let(:question_text) { Faker::Lorem.question }

  describe "base question" do
    let(:original_filename) { Faker::File.file_name }

    before do
      question.original_filename = original_filename
    end

    it_behaves_like "a question model"
  end

  describe "#update_answer" do
    let(:mock_s3_client) { Aws::S3::Client.new(stub_responses: true) }
    let(:uploaded_file) { instance_double(ActionDispatch::Http::UploadedFile) }
    let(:params) { { file: uploaded_file } }
    let(:original_filename) { "a-file.png" }
    let(:bucket) { "an-s3-bucket" }
    let(:key) { Faker::Alphanumeric.alphanumeric }
    let(:tempfile) { Tempfile.new(%w[temp-file .png]) }

    after do
      tempfile.unlink
    end

    before do
      allow(Aws::S3::Client).to receive(:new).and_return(mock_s3_client)
      allow(mock_s3_client).to receive(:put_object)
      allow(Settings.aws).to receive(:file_upload_s3_bucket_name).and_return(bucket)

      allow(uploaded_file).to receive_messages(original_filename: original_filename, tempfile: tempfile)

      allow(SecureRandom).to receive(:uuid).and_return key

      question.update_answer(params)
    end

    it "puts object to S3" do
      expect(mock_s3_client).to have_received(:put_object).with(
        body: tempfile,
        bucket: bucket,
        key: "#{key}.png",
      )
    end

    it "sets the uploaded_file_key" do
      expect(question.uploaded_file_key).to eq "#{key}.png"
    end

    it "sets the original_filename" do
      expect(question.original_filename).to eq original_filename
    end
  end

  describe "#show_answer" do
    let(:original_filename) { Faker::File.file_name }

    before do
      question.original_filename = original_filename
    end

    it "returns the original_filename" do
      expect(question.show_answer).to eq original_filename
    end
  end
end
