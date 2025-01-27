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

  describe "#before_save" do
    context "when a file was selected" do
      let(:mock_s3_client) { Aws::S3::Client.new(stub_responses: true) }
      let(:uploaded_file) { instance_double(ActionDispatch::Http::UploadedFile) }
      let(:original_filename) { "a-file.png" }
      let(:bucket) { "an-s3-bucket" }
      let(:key) { Faker::Alphanumeric.alphanumeric }
      let(:tempfile) { Tempfile.new(%w[temp-file .png]) }
      let(:file_size_in_bytes) { 2.megabytes }
      let(:file_type) { "image/png" }

      after do
        tempfile.unlink
      end

      before do
        allow(Aws::S3::Client).to receive(:new).and_return(mock_s3_client)
        allow(mock_s3_client).to receive(:put_object)
        allow(Settings.aws).to receive(:file_upload_s3_bucket_name).and_return(bucket)

        allow(uploaded_file).to receive_messages(original_filename: original_filename, tempfile: tempfile,
                                                 size: file_size_in_bytes, content_type: file_type)

        allow(SecureRandom).to receive(:uuid).and_return key

        allow(Rails.logger).to receive(:info).at_least(:once)

        question.file = uploaded_file

        question.before_save
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

      it "logs information about the file" do
        question.validate
        expect(Rails.logger).to have_received(:info).with("Uploaded file to S3 for file upload question",
                                                          { file_size_in_bytes:,
                                                            file_type: })
      end
    end

    context "when no file was selected (question was optional)" do
      it "sets the original_filename question attribute to a blank string" do
        question.before_save
        expect(question.original_filename).to eq ""
      end
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

  describe "#file_from_s3" do
    subject(:question) { described_class.new({ original_filename:, uploaded_file_key: }, options) }

    let(:mock_s3_client) { Aws::S3::Client.new(stub_responses: true) }
    let(:bucket) { "an-s3-bucket" }
    let(:get_object_output) { instance_double(Aws::S3::Types::GetObjectOutput) }
    let(:original_filename) { "a-file.png" }
    let(:uploaded_file_key) { Faker::Alphanumeric.alphanumeric }
    let(:tempfile) { Tempfile.new(%w[temp-file .png]) }
    let(:file_content) { Faker::Lorem.sentence }

    after do
      tempfile.unlink
    end

    before do
      File.write(tempfile, file_content)

      allow(Aws::S3::Client).to receive(:new).and_return(mock_s3_client)
      allow(mock_s3_client).to receive(:get_object).and_return(get_object_output)
      allow(get_object_output).to receive(:body).and_return(tempfile)
      allow(Settings.aws).to receive(:file_upload_s3_bucket_name).and_return(bucket)
    end

    it("reads file contents from S3") do
      expect(question.file_from_s3).to eq(file_content)
    end
  end

  describe "validations" do
    context "when the question is mandatory" do
      context "when no file is set" do
        it "returns an error" do
          expect(question).not_to be_valid
          expect(question.errors[:file]).to include "Select a file"
        end
      end
    end

    context "when the question is optional" do
      let(:is_optional) { true }

      context "when no file is set" do
        it "is valid" do
          expect(question).to be_valid
        end
      end
    end

    context "when the file size is greater than 7MB" do
      let(:uploaded_file) { instance_double(ActionDispatch::Http::UploadedFile) }
      let(:file_size_in_bytes) { 7.megabytes + 1 }
      let(:file_type) { "image/png" }

      before do
        allow(uploaded_file).to receive_messages(size: file_size_in_bytes, content_type: file_type)
        question.file = uploaded_file

        allow(Rails.logger).to receive(:info).at_least(:once)
      end

      it "returns an error" do
        expect(question).not_to be_valid
        expect(question.errors[:file]).to include "The selected file must be smaller than 7MB"
      end

      it "logs information about the file" do
        question.validate
        expect(Rails.logger).to have_received(:info).with("File upload question validation failed: file too big",
                                                          { file_size_in_bytes:,
                                                            file_type: })
      end
    end

    context "when the file type is not in the list of allowed file types" do
      let(:uploaded_file) { instance_double(ActionDispatch::Http::UploadedFile) }
      let(:file_size_in_bytes) { 7.megabytes }
      let(:file_type) { "text/javascript" }

      before do
        allow(uploaded_file).to receive_messages(size: file_size_in_bytes, content_type: file_type)
        question.file = uploaded_file

        allow(Rails.logger).to receive(:info).at_least(:once)
      end

      it "returns an error" do
        expect(question).not_to be_valid
        expect(question.errors[:file]).to include I18n.t("activemodel.errors.models.question/file.attributes.file.disallowed_type")
      end

      it "logs information about the file" do
        question.validate
        expect(Rails.logger).to have_received(:info).with("File upload question validation failed: disallowed file type",
                                                          { file_size_in_bytes:,
                                                            file_type: })
      end
    end

    Question::File::FILE_TYPES.each do |file_type|
      context "when the file type is #{file_type}" do
        let(:uploaded_file) { instance_double(ActionDispatch::Http::UploadedFile) }
        let(:file_size_in_bytes) { 7.megabytes }

        before do
          allow(uploaded_file).to receive_messages(size: file_size_in_bytes, content_type: file_type)
          question.file = uploaded_file

          allow(Rails.logger).to receive(:info).at_least(:once)
        end

        it "does not return an error" do
          expect(question).to be_valid
          expect(question.errors[:file]).to be_empty
        end

        it "does not log information about the file" do
          question.validate
          expect(Rails.logger).not_to have_received(:info)
        end
      end
    end

    context "when the file is valid" do
      let(:uploaded_file) { instance_double(ActionDispatch::Http::UploadedFile) }
      let(:file_size_in_bytes) { 7.megabytes }
      let(:file_type) { "text/plain" }

      before do
        allow(uploaded_file).to receive_messages(size: file_size_in_bytes, content_type: file_type)
        question.file = uploaded_file
      end

      it "is valid" do
        expect(question).to be_valid
      end
    end
  end
end
