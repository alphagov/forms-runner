require "rails_helper"

RSpec.describe SubmissionCsvService do
  subject(:service) { described_class.new(current_context:, submission_reference:, timestamp:, output_file_path: test_file.path) }

  let(:form) { build(:form, id: 1) }
  let(:first_step) { OpenStruct.new({ question_text: "What is the meaning of life?", show_answer: "42" }) }
  let(:second_step) { OpenStruct.new({ question_text: "What is your email address?", show_answer: "someone@example.com" }) }
  let(:current_context) { OpenStruct.new(form:, completed_steps: [first_step, second_step], support_details: OpenStruct.new(call_back_url: "http://gov.uk")) }
  let(:submission_reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }
  let(:timestamp) do
    Time.use_zone("London") { Time.zone.local(2022, 9, 14, 8, 0o0, 0o0) }
  end

  let(:test_file) { Tempfile.new("csv") }

  after do
    test_file.unlink
  end

  describe "#write" do
    it "writes submission to CSV file" do
      service.write
      expect(CSV.open(test_file.path).readlines).to eq(
        [
          ["Reference", "Submitted at", "What is the meaning of life?", "What is your email address?"],
          [submission_reference, "2022-09-14T08:00:00+01:00", "42", "someone@example.com"],
        ],
      )
    end
  end
end
