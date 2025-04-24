require "rails_helper"

RSpec.describe Question::File, type: :model do
  subject(:question) { described_class.new(attributes, options) }

  let(:attributes) { {} }

  let(:options) { { is_optional:, question_text: } }

  let(:is_optional) { false }
  let(:question_text) { Faker::Lorem.question }
  let(:extension) { ".png" }
  let(:tempfile) { Tempfile.new(["temp-file", extension]) }
  let(:original_filename) { "a-file#{extension}" }
  let(:file_size_in_bytes) { 2.megabytes }
  let(:file_type) { "image/png" }
  let(:file_content) { "not empty" }

  let(:uploaded_file) { instance_double(ActionDispatch::Http::UploadedFile) }
  let(:mock_file_upload_s3_service) { instance_double(Question::FileUploadS3Service) }

  before do
    File.write(tempfile, file_content)

    allow(Question::FileUploadS3Service).to receive(:new).and_return(mock_file_upload_s3_service)
    allow(uploaded_file).to receive_messages(original_filename: original_filename,
                                             tempfile: tempfile,
                                             size: file_size_in_bytes,
                                             content_type: file_type,
                                             path: tempfile.path)
  end

  after do
    tempfile.unlink
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
      let(:bucket) { "an-s3-bucket" }
      let(:uuid) { Faker::Alphanumeric.alphanumeric }
      let(:key) { "#{uuid}#{extension}" }

      before do
        allow(mock_file_upload_s3_service).to receive(:upload_to_s3)

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
                                                            { s3_object_key: key })
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
    let(:attributes) { { original_filename:, filename_suffix: } }
    let(:filename_suffix) { "" }
    let(:submission_reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }

    before do
      question.populate_email_filename(submission_reference:)
    end

    context "when the original_filename is blank" do
      let(:original_filename) { nil }

      it "returns a nil value" do
        expect(question.show_answer_in_email).to be_nil
      end
    end

    context "when the original_filename has a value" do
      it "returns the email_filename with the email attachment text" do
        expect(question.show_answer_in_email).to eq I18n.t("mailer.submission.file_attached", filename: question.email_filename)
      end
    end
  end

  describe "#show_answer_in_csv" do
    let(:attributes) { { original_filename:, filename_suffix: } }
    let(:original_filename) { Faker::File.file_name(dir: "", directory_separator: "") }
    let(:filename_suffix) { "" }
    let(:submission_reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }

    before do
      question.populate_email_filename(submission_reference:)
    end

    context "when the original_filename is blank" do
      let(:original_filename) { nil }

      it "returns a hash with the question text and a nil value" do
        expect(question.show_answer_in_csv(false)).to eq({ question.question_text => nil })
      end
    end

    context "when the original_filename has a value" do
      context "when is_s3_submission is false" do
        let(:original_filename) { Faker::File.file_name(dir: "", directory_separator: "") }

        it "returns a hash with the email_filename" do
          expect(question.show_answer_in_csv(false)).to eq({ question.question_text => question.email_filename })
        end
      end

      context "when is_s3_submission is true" do
        it "returns a hash with the filename_for_s3_submission" do
          expect(question.show_answer_in_csv(true)).to eq({ question.question_text => question.filename_for_s3_submission })
        end
      end
    end
  end

  describe "#filename_for_s3_submission" do
    let(:file_extension) { ".txt" }

    let(:original_filename) { "#{file_basename}#{file_extension}" }
    let(:filename_suffix) { "" }
    let(:maximum_file_basename_length) { 100 - filename_suffix.length - file_extension.length }

    let(:attributes) { { original_filename:, filename_suffix: } }

    context "when no suffix is supplied" do
      context "when the filename and extension are less than or equal to 100 characters" do
        let(:file_basename) { Faker::Alphanumeric.alpha(number: maximum_file_basename_length) }

        it "returns the original_filename" do
          expect(question.filename_for_s3_submission).to eq original_filename
          expect(question.filename_for_s3_submission.length).to eq 100
        end
      end

      context "when the filename and extension are over 100 characters" do
        let(:file_basename) { Faker::Alphanumeric.alpha(number: maximum_file_basename_length + 1) }

        it "returns the original_filename" do
          truncated_basename = file_basename.truncate(maximum_file_basename_length, omission: "")
          truncated_filename = "#{truncated_basename}#{file_extension}"
          expect(question.filename_for_s3_submission).to eq truncated_filename
          expect(question.filename_for_s3_submission.length).to eq 100
        end
      end
    end

    context "when a suffix is supplied" do
      let(:filename_suffix) { "_1" }

      context "when the filename, suffix and extension are less than or equal to 100 characters" do
        let(:file_basename) { Faker::Alphanumeric.alpha(number: maximum_file_basename_length) }

        it "returns the original filename with the suffix" do
          filename_with_suffix = "#{file_basename}#{filename_suffix}#{file_extension}"
          expect(question.filename_for_s3_submission).to eq filename_with_suffix
          expect(question.filename_for_s3_submission.length).to eq 100
        end
      end

      context "when the filename, suffix and extension are over 100 characters" do
        let(:file_basename) { Faker::Alphanumeric.alpha(number: maximum_file_basename_length + 1) }

        it "returns the truncated filename with suffix" do
          truncated_basename = file_basename.truncate(maximum_file_basename_length, omission: "")
          truncated_filename_with_suffix = "#{truncated_basename}#{filename_suffix}#{file_extension}"
          expect(question.filename_for_s3_submission).to eq truncated_filename_with_suffix
          expect(question.filename_for_s3_submission.length).to eq 100
        end
      end
    end
  end

  describe "filename_after_reference_truncation" do
    let(:attributes) { { original_filename: } }

    context "when the filename and extension are less than or equal to 100 characters" do
      let(:original_filename) { "this_is_fairly_long_filename_that_is_luckily_just_short_enough_to_avoid_being_truncated.xlsx" }

      it "returns the original_filename" do
        expect(question.filename_after_reference_truncation).to eq original_filename
      end
    end

    context "when the filename and extension are over 100 characters" do
      let(:original_filename) { "this_is_an_incredibly_long_filename_that_will_surely_have_to_be_truncated_somewhere_near_the_end.xlsx" }

      it "returns the original_filename" do
        truncated_filename = "this_is_an_incredibly_long_filename_that_will_surely_have_to_be_truncated_somewhere_nea.xlsx"
        expect(question.filename_after_reference_truncation).to eq truncated_filename
      end
    end
  end

  describe "populate_email_filename" do
    let(:submission_reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }
    let(:attributes) { { original_filename:, filename_suffix: } }

    context "when no suffix is supplied" do
      let(:filename_suffix) { "" }

      context "when the filename and extension are less than or equal to 100 characters" do
        let(:original_filename) { "a_very_very_long_filename_that_is_very_nearly_but_not_quite_long_enough_to_be_truncated.txt" }

        it "sets email_filename to the original_filename with the submission reference" do
          expect { question.populate_email_filename(submission_reference:) }.to change(question, :email_filename).from("").to("a_very_very_long_filename_that_is_very_nearly_but_not_quite_long_enough_to_be_truncated_#{submission_reference}.txt")
          expect(question.email_filename.length).to eq 100
        end
      end

      context "when the filename and extension are over 100 characters" do
        let(:original_filename) { "a_very_very_very_very_very_very_very_long_filename_just_about_long_enough_for_truncation.png" }

        it "sets email_filename to the a truncated original_filename with the submission reference" do
          expect { question.populate_email_filename(submission_reference:) }.to change(question, :email_filename).from("").to("a_very_very_very_very_very_very_very_long_filename_just_about_long_enough_for_truncatio_#{submission_reference}.png")
          expect(question.email_filename.length).to eq 100
        end
      end
    end

    context "when a suffix is supplied" do
      let(:filename_suffix) { "_1" }

      context "when the filename, suffix and extension are less than or equal to 100 characters" do
        let(:original_filename) { "a_very_very_long_filename_thats_very_nearly_but_not_quite_long_enough_to_be_truncated.jpg" }

        it "sets email_filename to the original filename with the suffix and reference" do
          filename_with_suffix_and_reference = "a_very_very_long_filename_thats_very_nearly_but_not_quite_long_enough_to_be_truncated_1_#{submission_reference}.jpg"
          expect { question.populate_email_filename(submission_reference:) }.to change(question, :email_filename).from("").to(filename_with_suffix_and_reference)
          expect(question.email_filename.length).to eq 100
        end
      end

      context "when the filename, suffix and extension are over 100 characters" do
        let(:original_filename) { "an_unusual_and_atypically_long_filename_that_is_just_about_long_enough_to_be_truncated.doc" }

        it "sets email_filename to the truncated filename with suffix and reference" do
          truncated_filename_with_suffix_and_reference = "an_unusual_and_atypically_long_filename_that_is_just_about_long_enough_to_be_truncate_1_#{submission_reference}.doc"

          expect { question.populate_email_filename(submission_reference:) }.to change(question, :email_filename).from("").to(truncated_filename_with_suffix_and_reference)
          expect(question.email_filename.length).to eq 100
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
        question.file = uploaded_file
      end

      it "returns an error" do
        expect(question).not_to be_valid
        expect(question.errors[:file]).to include "The selected file must be smaller than 7MB"
      end
    end

    context "when the file size is empty" do
      let(:file_content) { "" }

      before do
        question.file = uploaded_file
      end

      it "returns an error" do
        expect(question).not_to be_valid
        expect(question.errors[:file]).to include "The selected file is empty"
      end
    end

    context "when the file type is not in the list of allowed file types" do
      let(:uploaded_file) { instance_double(ActionDispatch::Http::UploadedFile) }
      let(:file_size_in_bytes) { 7.megabytes }
      let(:file_type) { "text/javascript" }

      before do
        question.file = uploaded_file
      end

      it "returns an error" do
        expect(question).not_to be_valid
        expect(question.errors[:file]).to include I18n.t("activemodel.errors.models.question/file.attributes.file.disallowed_type")
      end
    end

    Question::File::FILE_TYPES.each do |file_type|
      context "when the file type is #{file_type}" do
        let(:uploaded_file) { instance_double(ActionDispatch::Http::UploadedFile) }
        let(:file_size_in_bytes) { 7.megabytes }

        before do
          allow(uploaded_file).to receive_messages(size: file_size_in_bytes, content_type: file_type)
          question.file = uploaded_file
        end

        it "does not return an error" do
          expect(question).to be_valid
          expect(question.errors[:file]).to be_empty
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
