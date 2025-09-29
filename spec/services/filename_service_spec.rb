require "rails_helper"

RSpec.describe FilenameService do
  subject(:service) { described_class }

  describe ".sanitize" do
    [
      ["", ""],
      ["foobar.jpg", "foobar.jpg"],
      ["foo/bar.jpg", "foobar.jpg"],
      ["foo\\bar.jpg", "foobar.jpg"],
      ["foo:bar.jpg", "foobar.jpg"],
      ["foo*bar.jpg", "foobar.jpg"],
      ["foobar?.jpg", "foobar.jpg"],
      ["\"foobar\".jpg", "foobar.jpg"],
      ["foo<bar>.jpg", "foobar.jpg"],
      ["foo|bar|.jpg", "foobar.jpg"],
    ].each do |filename, sanitized|
      it "sanitizes '#{filename}'" do
        expect(service.sanitize(filename)).to eq sanitized
      end
    end
  end

  describe "#to_s3_submission" do
    let(:file_extension) { ".txt" }

    let(:original_filename) { "#{file_basename}#{file_extension}" }
    let(:filename_suffix) { "" }
    let(:maximum_file_basename_length) { 100 - filename_suffix.length - file_extension.length }

    context "when no suffix is supplied" do
      subject(:to_s3_submission) { service.to_s3_submission(original_filename) }

      context "when the filename and extension are less than or equal to 100 characters" do
        let(:file_basename) { Faker::Alphanumeric.alpha(number: maximum_file_basename_length) }

        it "returns the original_filename" do
          expect(to_s3_submission).to eq original_filename
          expect(to_s3_submission.length).to eq 100
        end
      end

      context "when the filename and extension are over 100 characters" do
        let(:file_basename) { Faker::Alphanumeric.alpha(number: maximum_file_basename_length + 1) }

        it "truncates the filename" do
          truncated_basename = file_basename.truncate(maximum_file_basename_length, omission: "")
          truncated_filename = "#{truncated_basename}#{file_extension}"
          expect(to_s3_submission).to eq truncated_filename
          expect(to_s3_submission.length).to eq 100
        end
      end

      context "when the filename contains illegal characters" do
        let(:original_filename) { "\"a\"_<>:/\\?*very_very_very_very_very_very_very_very_very_long_filename_just_about_long_enough_for_truncation.png" }

        it "returns a filename with the illegal characters removed" do
          expect(to_s3_submission).to eq "a_very_very_very_very_very_very_very_very_very_long_filename_just_about_long_enough_for_truncati.png"
          expect(to_s3_submission.length).to eq 100
        end
      end
    end

    context "when a suffix is supplied" do
      subject(:to_s3_submission) { service.to_s3_submission(original_filename, suffix: filename_suffix) }

      let(:filename_suffix) { "_1" }

      context "when the filename, suffix and extension are less than or equal to 100 characters" do
        let(:file_basename) { Faker::Alphanumeric.alpha(number: maximum_file_basename_length) }

        it "returns the original filename with the suffix" do
          filename_with_suffix = "#{file_basename}#{filename_suffix}#{file_extension}"
          expect(to_s3_submission).to eq filename_with_suffix
          expect(to_s3_submission.length).to eq 100
        end
      end

      context "when the filename, suffix and extension are over 100 characters" do
        let(:file_basename) { Faker::Alphanumeric.alpha(number: maximum_file_basename_length + 1) }

        it "returns the truncated filename with suffix" do
          truncated_basename = file_basename.truncate(maximum_file_basename_length, omission: "")
          truncated_filename_with_suffix = "#{truncated_basename}#{filename_suffix}#{file_extension}"
          expect(to_s3_submission).to eq truncated_filename_with_suffix
          expect(to_s3_submission.length).to eq 100
        end
      end
    end
  end

  describe "filename_after_reference_truncation" do
    let(:truncate_for_reference) { service.truncate_for_reference(original_filename) }

    context "when the filename and extension are less than or equal to 100 characters" do
      let(:original_filename) { "this_is_fairly_long_filename_that_is_luckily_just_short_enough_to_avoid_being_truncated.xlsx" }

      it "returns the original_filename" do
        expect(truncate_for_reference).to eq original_filename
      end
    end

    context "when the filename and extension are over 100 characters" do
      let(:original_filename) { "this_is_an_incredibly_long_filename_that_will_surely_have_to_be_truncated_somewhere_near_the_end.xlsx" }

      it "returns the original_filename" do
        truncated_filename = "this_is_an_incredibly_long_filename_that_will_surely_have_to_be_truncated_somewhere_nea.xlsx"
        expect(truncate_for_reference).to eq truncated_filename
      end
    end

    context "when the filename contains illegal characters" do
      let(:original_filename) { "\"this\"_<>:/\\?*is_an_incredibly_long_filename_that_will_surely_have_to_be_truncated_somewhere_near_the_end.xlsx" }

      it "returns a filename with illegal characters removed" do
        truncated_filename = "this_is_an_incredibly_long_filename_that_will_surely_have_to_be_truncated_somewhere_nea.xlsx"
        expect(truncate_for_reference).to eq truncated_filename
      end
    end
  end

  describe "to_email_attachment" do
    let(:submission_reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }

    context "when no suffix is supplied" do
      subject(:to_email_attachment) { service.to_email_attachment(original_filename, submission_reference:) }

      context "when the filename and extension are less than or equal to 100 characters" do
        let(:original_filename) { "a_very_very_long_filename_that_is_very_nearly_but_not_quite_long_enough_to_be_truncated.txt" }

        it "sets email_filename to the original_filename with the submission reference" do
          expect(to_email_attachment).to eq "a_very_very_long_filename_that_is_very_nearly_but_not_quite_long_enough_to_be_truncated_#{submission_reference}.txt"
          expect(to_email_attachment.length).to eq 100
        end
      end

      context "when the filename and extension are over 100 characters" do
        let(:original_filename) { "a_very_very_very_very_very_very_very_long_filename_just_about_long_enough_for_truncation.png" }

        it "sets email_filename to the a truncated original_filename with the submission reference" do
          expect(to_email_attachment).to eq "a_very_very_very_very_very_very_very_long_filename_just_about_long_enough_for_truncatio_#{submission_reference}.png"
          expect(to_email_attachment.length).to eq 100
        end
      end

      context "when the filename contains illegal characters" do
        let(:original_filename) { "\"a\"_<>:/\\?*very_very_very_very_very_very_very_long_filename_just_about_long_enough_for_truncation.png" }

        it "returns a filename with the illegal characters removed" do
          expect(to_email_attachment).to eq "a_very_very_very_very_very_very_very_long_filename_just_about_long_enough_for_truncatio_#{submission_reference}.png"
          expect(to_email_attachment.length).to eq 100
        end
      end
    end

    context "when a suffix is supplied" do
      subject(:to_email_attachment) { service.to_email_attachment(original_filename, submission_reference:, suffix: filename_suffix) }

      let(:filename_suffix) { "_1" }

      context "when the filename, suffix and extension are less than or equal to 100 characters" do
        let(:original_filename) { "a_very_very_long_filename_thats_very_nearly_but_not_quite_long_enough_to_be_truncated.jpg" }

        it "sets email_filename to the original filename with the suffix and reference" do
          filename_with_suffix_and_reference = "a_very_very_long_filename_thats_very_nearly_but_not_quite_long_enough_to_be_truncated_1_#{submission_reference}.jpg"
          expect(to_email_attachment).to eq filename_with_suffix_and_reference
          expect(to_email_attachment.length).to eq 100
        end
      end

      context "when the filename, suffix and extension are over 100 characters" do
        let(:original_filename) { "an_unusual_and_atypically_long_filename_that_is_just_about_long_enough_to_be_truncated.doc" }

        it "sets email_filename to the truncated filename with suffix and reference" do
          truncated_filename_with_suffix_and_reference = "an_unusual_and_atypically_long_filename_that_is_just_about_long_enough_to_be_truncate_1_#{submission_reference}.doc"

          expect(to_email_attachment).to eq truncated_filename_with_suffix_and_reference
          expect(to_email_attachment.length).to eq 100
        end
      end
    end
  end
end
