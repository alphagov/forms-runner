require "rails_helper"

RSpec.describe NotifyService do
  let(:notify_reference) { SecureRandom.uuid }

  context "with api key set" do
    let(:notify_api_key) { "test-key" }

    context "with a time in BST" do
      let(:submission_datetime) { Time.utc(2022, 9, 14, 10, 0o0, 0o0) }

      it "sends correct values to notify" do
        fake_notify_client = instance_double(Notifications::Client)
        allow(fake_notify_client).to receive(:send_email)
        allow(Notifications::Client).to receive(:new).and_return(fake_notify_client)
        Settings.govuk_notify.api_key = notify_api_key
        Settings.govuk_notify.form_submission_email_template_id = "testing-123"

        travel_to submission_datetime do
          notify_service = described_class.new
          form = OpenStruct.new(submission_email: "fake-email", form_name: "title", steps: [OpenStruct.new(question_text: "text", show_answer: "Testing")])
          notify_service.send_email(form, notify_reference)
          expect(fake_notify_client).to have_received(:send_email).with(
            { email_address: "fake-email",
              personalisation: {
                submission_date: "14 September 2022",
                submission_time: "11:00:00",
                text_input: "# text\nTesting\n",
                title: "title",
              },
              reference: notify_reference,
              template_id: "testing-123" },
          ).once
        end
      end
    end

    context "with a time in GMT" do
      let(:submission_datetime) { Time.utc(2022, 12, 14, 10, 0o0, 0o0) }

      it "sends correct values to notify" do
        fake_notify_client = instance_double(Notifications::Client)
        allow(fake_notify_client).to receive(:send_email)
        allow(Notifications::Client).to receive(:new).and_return(fake_notify_client)
        Settings.govuk_notify.form_submission_email_template_id = "testing-123"

        travel_to submission_datetime do
          notify_service = described_class.new
          form = OpenStruct.new(submission_email: "fake-email", form_name: "title", steps: [OpenStruct.new(question_text: "text", show_answer: "Testing")])
          notify_service.send_email(form, notify_reference)
          expect(fake_notify_client).to have_received(:send_email).with(
            { email_address: "fake-email",
              personalisation: {
                submission_date: "14 December 2022",
                submission_time: "10:00:00",
                text_input: "# text\nTesting\n",
                title: "title",
              },
              reference: notify_reference,
              template_id: "testing-123" },
          ).once
        end
      end
    end

    context "with an email subject identifying that it was submitted from preview-form" do
      let(:submission_datetime) { Time.utc(2022, 12, 14, 10, 0o0, 0o0) }

      it "sends correct values to notify" do
        fake_notify_client = instance_double(Notifications::Client)
        allow(fake_notify_client).to receive(:send_email)
        allow(Notifications::Client).to receive(:new).and_return(fake_notify_client)
        Settings.govuk_notify.form_submission_email_template_id = "testing-123"

        travel_to submission_datetime do
          notify_service = described_class.new
          form = OpenStruct.new(submission_email: "fake-email", form_name: "title", steps: [OpenStruct.new(question_text: "text", show_answer: "Testing")])
          notify_service.send_email(form, notify_reference, preview_mode: true)
          expect(fake_notify_client).to have_received(:send_email).with(
            { email_address: "fake-email",
              personalisation: {
                submission_date: "14 December 2022",
                submission_time: "10:00:00",
                text_input: "# text\nTesting\n",
                title: "TEST FORM: title",
              },
              reference: notify_reference,
              template_id: "testing-123" },
          ).once
        end
      end
    end
  end

  context "with no api key set" do
    it "does not send an email through notify" do
      Settings.govuk_notify.api_key = nil
      fake_notify_client = instance_double(Notifications::Client)
      allow(fake_notify_client).to receive(:send_email)
      allow(Notifications::Client).to receive(:new).and_return(fake_notify_client)
      expect(Rails.logger).to receive(:warn).with(/NOTIFY_API_KEY/)

      notify_service = described_class.new
      form = OpenStruct.new(submission_email: "fake-email", form_name: "title", steps: [OpenStruct.new(question_text: "text", show_answer: "Testing")])
      notify_service.send_email(form, notify_reference)
      expect(fake_notify_client).not_to have_received(:send_email)
    end
  end

  describe "#build_question_answers_section" do
    let(:notify_service) { described_class.new }

    let(:form) { OpenStruct.new(steps: [step]) }

    let(:step) { OpenStruct.new({ question_text: "What is the meaning of life?", show_answer: "42" }) }

    it "returns combined title and answer" do
      expect(notify_service.build_question_answers_section(form)).to eq "# What is the meaning of life?\n42\n"
    end

    context "when there is more than one step" do
      let(:form) { OpenStruct.new(steps: [step, step]) }

      it "contains a horizontal rule between each step" do
        expect(notify_service.build_question_answers_section(form)).to include "\n\n---\n\n"
      end
    end
  end

  describe "#prep_question_title" do
    it "returns markdown heading on its own line" do
      notify_service = described_class.new
      ["Hello", "3.4 Question", "-23.4 Negative headings", "\n\n # 4.5.6"].each do |title|
        expect(notify_service.prep_question_title(title)).to eq "# #{title}\n"
      end
    end
  end

  describe "#prep_answer_text" do
    let(:notify_service) { described_class.new }

    it "returns escaped answer" do
      [
        { input: "Hello", output: "Hello" },
        { input: "3.4 Question", output: "3\\.4 Question" },
        { input: "-23.4 answer", output: "\\-23\\.4 answer" },
        { input: "4.5.6", output: "4\\.5\\.6" },
        { input: "\n\n# Test \n\n## Test 2", output: "\\# Test\n\n\\#\\# Test 2" },
        { input: "\n\n```# Test 3\n\n## Test 4", output: "\\`\\`\\`\\# Test 3\n\n\\#\\# Test 4" }, # escapes ```
        { input: "\n\n\n\n\n```# Test \n\n\n\n\n\n## Test 3\n\n\n\n", output: "\\`\\`\\`\\# Test\n\n\\#\\# Test 3" },
        { input: "test https://example.org # more text 19.5\n\nA new paragraph.", output: "test https://example.org \\# more text 19\\.5\n\nA new paragraph\\." },
        { input: "test https://example.org # more text 19.5\n\nA new paragraph.\n\n# another link http://gov.uk", output: "test https://example.org \\# more text 19\\.5\n\nA new paragraph\\.\n\n\\# another link http://gov.uk" },
        { input: "not a title\n====", output: "not a title\n\\_\\_\\_\\_" },
        { input: "a normal sentence: 10 = 5 + 5", output: "a normal sentence: 10 = 5 \\+ 5" },
        { input: "    paragraph 1\n\n\n\n\n\n\n\n\n\n\n\n\n Another Paragraph with trailing space     \n\n\n\n\n", output: "paragraph 1\n\nAnother Paragraph with trailing space" },

      ].each do |test_case|
        expect(notify_service.prep_answer_text(test_case[:input])).to eq test_case[:output]
      end
    end

    context "when answer is blank i.e skipped" do
      it "returns the blank answer text" do
        expect(notify_service.prep_answer_text("")).to eq "\\[This question was skipped\\]"
      end
    end
  end
end
