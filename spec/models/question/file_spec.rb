require "rails_helper"

RSpec.describe Question::File, type: :model do
  subject(:question) { described_class.new(attributes, options) }

  let(:attributes) { {} }

  let(:options) { { is_optional:, question_text: } }

  let(:is_optional) { false }
  let(:question_text) { Faker::Lorem.question }

  let(:mock_file_upload_s3_service) { instance_double(Question::FileUploadS3Service) }

  before do
    allow(Question::FileUploadS3Service).to receive(:new).and_return(mock_file_upload_s3_service)
  end

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
      let(:extension) { ".png" }
      let(:original_filename) { "a-file#{extension}" }
      let(:bucket) { "an-s3-bucket" }
      let(:uuid) { Faker::Alphanumeric.alphanumeric }
      let(:key) { "#{uuid}#{extension}" }
      let(:tempfile) { Tempfile.new(["temp-file", extension]) }
      let(:file_size_in_bytes) { 2.megabytes }
      let(:file_type) { "image/png" }

      after do
        tempfile.unlink
      end

      before do
        allow(mock_file_upload_s3_service).to receive(:upload_to_s3)

        allow(uploaded_file).to receive_messages(original_filename: original_filename, tempfile: tempfile,
                                                 size: file_size_in_bytes, content_type: file_type)

        allow(SecureRandom).to receive(:uuid).and_return uuid

        allow(Rails.logger).to receive(:info).at_least(:once)

        question.file = uploaded_file
      end

      context "when the virus scan successfully returns a status" do
        let(:scan_status) { Question::File::NO_THREATS_FOUND_SCAN_STATUS }

        before do
          allow(mock_file_upload_s3_service).to receive(:poll_for_scan_status).and_return(scan_status)
          question.before_save
        end

        it "puts object to S3" do
          expect(mock_file_upload_s3_service).to have_received(:upload_to_s3).with(tempfile, key)
        end

        it "sets the uploaded_file_key" do
          expect(question.uploaded_file_key).to eq key
        end

        it "sets the original_filename" do
          expect(question.original_filename).to eq original_filename
        end

        it "logs information about the file" do
          expect(Rails.logger).to have_received(:info).with("Uploaded file to S3 for file upload question",
                                                            { file_size_in_bytes:,
                                                              file_type:,
                                                              s3_object_key: key })
        end

        it "does not add any errors" do
          expect(question.errors).to be_empty
        end

        context "when the scan returns the threats found status" do
          let(:scan_status) { Question::File::THREATS_FOUND_SCAN_STATUS }

          it "does adds a contains_virus error" do
            expect(question.errors[:file]).to include "The selected file contains a virus"
          end
        end

        context "when the scan returns a different status" do
          let(:scan_status) { "FAILURE" }

          it "does adds a contains_virus error" do
            expect(question.errors[:file]).to include "The selected file could not be uploaded - try again"
          end
        end
      end

      context "when the scan times out" do
        before do
          allow(mock_file_upload_s3_service).to receive(:poll_for_scan_status).and_raise(Question::FileUploadS3Service::PollForScanResultTimeoutError)
          allow(Rails.logger).to receive(:error).at_least(:once)

          question.before_save
        end

        let(:scan_status) { nil }

        it "adds a contains_virus error" do
          expect(question.errors[:file]).to include "The selected file could not be uploaded - try again"
        end

        it "logs an error" do
          expect(Rails.logger).to have_received(:error).once.with(
            "Timed out polling for GuardDuty scan status for uploaded file",
            { s3_object_key: key },
          )
        end
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
    let(:original_filename) { Faker::File.file_name(dir: "", directory_separator: "") }

    before do
      question.original_filename = original_filename
    end

    it "returns the original_filename" do
      expect(question.show_answer).to eq original_filename
    end

    context "when the file has a suffix set" do
      let(:attributes) { { original_filename:, filename_suffix: } }
      let(:filename_suffix) { "_1" }

      it "returns the filename without a suffix" do
        expect(question.show_answer).to eq original_filename
      end
    end
  end

  describe "#show_answer_in_email" do
    let(:original_filename) { Faker::File.file_name(dir: "", directory_separator: "") }
    let(:attributes) { { original_filename: } }

    it "returns the original_filename" do
      expect(question.show_answer_in_email).to eq I18n.t("mailer.submission.file_attached", filename: question.name_with_filename_suffix)
    end

    context "when the file has a suffix set" do
      let(:attributes) { { original_filename:, filename_suffix: } }
      let(:filename_suffix) { "_1" }

      it "returns the filename with a suffix" do
        expect(question.show_answer_in_email).to eq I18n.t("mailer.submission.file_attached", filename: question.name_with_filename_suffix)
      end
    end
  end

  describe "#show_answer_in_csv" do
    let(:original_filename) { Faker::File.file_name(dir: "", directory_separator: "") }
    let(:attributes) { { original_filename: } }

    it "returns the original_filename" do
      expect(question.show_answer_in_csv).to eq({ question.question_text => question.name_with_filename_suffix })
    end

    context "when the file has a suffix set" do
      let(:attributes) { { original_filename:, filename_suffix: } }
      let(:filename_suffix) { "_1" }

      it "returns the filename with a suffix" do
        expect(question.show_answer_in_csv).to eq({ question.question_text => question.name_with_filename_suffix })
      end
    end
  end

  describe "name_with_filename_suffix" do
    let(:file_extension) { ".txt" }

    let(:original_filename) { "#{file_basename}#{file_extension}" }
    let(:filename_suffix) { "" }
    let(:maximum_file_basename_length) { 100 - filename_suffix.length - file_extension.length }

    let(:attributes) { { original_filename:, filename_suffix: } }

    context "when no suffix is supplied" do
      context "when the filename and extension are less than or equal to 100 characters" do
        let(:file_basename) { Faker::Alphanumeric.alpha(number: maximum_file_basename_length) }

        it "returns the original_filename" do
          expect(question.name_with_filename_suffix).to eq original_filename
          expect(question.name_with_filename_suffix.length).to eq 100
        end
      end

      context "when the filename and extension are over 100 characters" do
        let(:file_basename) { Faker::Alphanumeric.alpha(number: maximum_file_basename_length + 1) }

        it "returns the original_filename" do
          truncated_basename = file_basename.truncate(maximum_file_basename_length, omission: "")
          truncated_filename = "#{truncated_basename}#{file_extension}"
          expect(question.name_with_filename_suffix).to eq truncated_filename
          expect(question.name_with_filename_suffix.length).to eq 100
        end
      end
    end

    context "when a suffix is supplied" do
      let(:filename_suffix) { "_1" }

      context "when the filename, suffix and extension are less than or equal to 100 characters" do
        let(:file_basename) { Faker::Alphanumeric.alpha(number: maximum_file_basename_length) }

        it "returns the original filename with the suffix" do
          filename_with_suffix = "#{file_basename}#{filename_suffix}#{file_extension}"
          expect(question.name_with_filename_suffix).to eq filename_with_suffix
          expect(question.name_with_filename_suffix.length).to eq 100
        end
      end

      context "when the filename, suffix and extension are over 100 characters" do
        let(:file_basename) { Faker::Alphanumeric.alpha(number: maximum_file_basename_length + 1) }

        it "returns the truncated filename with suffix" do
          truncated_basename = file_basename.truncate(maximum_file_basename_length, omission: "")
          truncated_filename_with_suffix = "#{truncated_basename}#{filename_suffix}#{file_extension}"
          expect(question.name_with_filename_suffix).to eq truncated_filename_with_suffix
          expect(question.name_with_filename_suffix.length).to eq 100
        end
      end
    end
  end

  describe "#file_from_s3" do
    let(:attributes) { { original_filename:, uploaded_file_key: } }

    let(:original_filename) { "a-file.png" }
    let(:uploaded_file_key) { Faker::Alphanumeric.alphanumeric }
    let(:file_content) { Faker::Lorem.sentence }

    before do
      allow(mock_file_upload_s3_service).to receive(:file_from_s3).with(uploaded_file_key).and_return(file_content)
    end

    it("reads file contents from S3") do
      expect(question.file_from_s3).to eq(file_content)
    end
  end

  describe "#delete_from_s3" do
    let(:attributes) { { original_filename: "a-file.png", uploaded_file_key: } }

    let(:uploaded_file_key) { Faker::Alphanumeric.alphanumeric }

    before do
      allow(mock_file_upload_s3_service).to receive(:delete_from_s3)
    end

    it("calls S3 to delete the file") do
      expect(mock_file_upload_s3_service).to receive(:delete_from_s3).with(uploaded_file_key)
      question.delete_from_s3
    end
  end

  describe "#file_uploaded?" do
    let(:attributes) { { uploaded_file_key: } }

    context "when a file has been uploaded" do
      let(:uploaded_file_key) { Faker::Alphanumeric.alphanumeric }

      it "returns true" do
        expect(question.file_uploaded?).to be true
      end
    end

    context "when a file has not been uploaded" do
      let(:uploaded_file_key) { nil }

      it "returns false" do
        expect(question.file_uploaded?).to be false
      end
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
