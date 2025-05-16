require "rails_helper"

RSpec.describe CurrentRequestLoggingAttributes, type: :model do
  subject(:current) { described_class.new }

  describe "#as_hash" do
    it "includes only properties that are set" do
      current.form_id = 1
      expect(current.as_hash).to eq({ form_id: 1 })
    end

    it "includes all properties when they are set" do
      current.request_host = "www.example.com"
      current.request_id = "a-request-id"
      current.form_id = 1
      current.form_name = "A form"
      current.preview = false
      current.page_id = 2
      current.page_slug = "a-page"
      current.answer_type = "text"
      current.session_id_hash = "a-session-id"
      current.trace_id = "a-trace-id"
      current.question_number = 3
      current.submission_reference = "a-submission-ref"
      current.confirmation_email_reference = "a-confirmation-email-ref"
      current.confirmation_email_id = "a-confirmation-email-id"
      current.rescued_exception = "StandardError"
      current.rescued_exception_trace = "a trace"
      current.validation_errors = ["text: blank"]
      current.answer_metadata = { foo: "bar" }

      expect(current.as_hash).to eq({
        request_host: "www.example.com",
        request_id: "a-request-id",
        form_id: 1,
        form_name: "A form",
        preview: "false",
        page_id: 2,
        page_slug: "a-page",
        answer_type: "text",
        session_id_hash: "a-session-id",
        trace_id: "a-trace-id",
        question_number: 3,
        submission_reference: "a-submission-ref",
        notification_references: {
          confirmation_email_reference: "a-confirmation-email-ref",
        },
        notification_ids: {
          confirmation_email_id: "a-confirmation-email-id",
        },
        rescued_exception: "StandardError",
        rescued_exception_trace: "a trace",
        validation_errors: ["text: blank"],
        answer_metadata: { foo: "bar" },
      })
    end

    it "does not include nil entries in notification_references hash" do
      if current.as_hash.key?(:notification_references)
        expect(current.as_hash[:notification_references].keys).not_to include :confirmation_email_reference
      else
        expect(current.as_hash.key?(:notification_references)).to be false
      end
    end

    it "does not include nil entries in notification_ids hash" do
      if current.as_hash.key?(:notification_ids)
        expect(current.as_hash[:notification_ids].keys).not_to include :confirmation_email_id
      else
        expect(current.as_hash.key?(:notification_ids)).to be false
      end
    end

    it "does not include the validation errors array if empty" do
      current.validation_errors = []

      expect(current.as_hash.keys).not_to include :validation_errors
    end

    it "does not include the answer metadata if hash is empty" do
      current.answer_metadata = {}

      expect(current.as_hash.keys).not_to include :answer_metadata
    end
  end
end
