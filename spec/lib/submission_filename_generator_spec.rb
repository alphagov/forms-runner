require "rails_helper"

RSpec.describe SubmissionFilenameGenerator do
  describe "#csv_filename" do
    let(:submission_reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }

    context "when there is a long form name that would cause the filename to be longer than 100 characters" do
      let(:form_name) { "A form name that will cause the filename to be truncated to obey the limittt" }

      it "truncates the form name in the filename" do
        filename = described_class.csv_filename(form_name:, submission_reference:)
        expect(filename).to eq("govuk_forms_a_form_name_that_will_cause_the_filename_to_be_truncated_to_obey_the_#{submission_reference}.csv")
      end
    end

    context "when the form name would cause the filename to be exactly 100 characters long" do
      let(:form_name) { "A form name that will cause the filename to be 100 characters long exactlyy" }

      it "does not truncate the form name in the filename" do
        filename = described_class.csv_filename(form_name:, submission_reference:)
        expect(filename).to eq("govuk_forms_a_form_name_that_will_cause_the_filename_to_be_100_characters_long_exactlyy_#{submission_reference}.csv")
      end
    end
  end

  describe "#json_filename" do
    let(:submission_reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }

    context "when there is a long form name that would cause the filename to be longer than 100 characters" do
      let(:form_name) { "A form name that will cause the filename to be truncated to obey the limitt" }

      it "truncates the form name in the filename" do
        filename = described_class.json_filename(form_name:, submission_reference:)
        expect(filename).to eq("govuk_forms_a_form_name_that_will_cause_the_filename_to_be_truncated_to_obey_the_#{submission_reference}.json")
      end
    end

    context "when the form name would cause the filename to be exactly 100 characters long" do
      let(:form_name) { "A form name that will cause the filename to be 100 characters long exactly" }

      it "does not truncate the form name in the filename" do
        filename = described_class.json_filename(form_name:, submission_reference:)
        expect(filename).to eq("govuk_forms_a_form_name_that_will_cause_the_filename_to_be_100_characters_long_exactly_#{submission_reference}.json")
      end
    end
  end
end
