require "rails_helper"

RSpec.describe CurrentLoggingAttributes, type: :model do
  subject(:current) { described_class.new }

  let(:submission_email_id) { "a-submission-email-id" }
  let(:submission_email_reference) { "a-submission-email-ref" }

  describe "#as_hash" do
    it "includes only properties that are set" do
      current.form_id = 1
      expect(current.as_hash).to eq({ form_id: 1 })
    end

    it "includes all properties when they are set" do
      current.host = "www.example.com"
      current.request_id = "a-request-id"
      current.form_id = 1
      current.form_name = "A form"
      current.page_id = 2
      current.page_slug = "a-page"
      current.session_id_hash = "a-session-id"
      current.trace_id = "a-trace-id"
      current.question_number = 3
      current.submission_reference = "a-submission-ref"
      current.submission_email_reference = submission_email_reference
      current.submission_email_id = submission_email_id
      current.confirmation_email_reference = "a-confirmation-email-ref"
      current.confirmation_email_id = "a-confirmation-email-id"
      current.rescued_exception = "StandardError"
      current.rescued_exception_trace = "a trace"

      expect(current.as_hash).to eq({
        host: "www.example.com",
        request_id: "a-request-id",
        form_id: 1,
        form_name: "A form",
        page_id: 2,
        page_slug: "a-page",
        session_id_hash: "a-session-id",
        trace_id: "a-trace-id",
        question_number: 3,
        submission_reference: "a-submission-ref",
        notification_references: {
          submission_email_reference:,
          confirmation_email_reference: "a-confirmation-email-ref",
        },
        notification_ids: {
          submission_email_id:,
          confirmation_email_id: "a-confirmation-email-id",
        },
        rescued_exception: "StandardError",
        rescued_exception_trace: "a trace",
      })
    end

    it "does not include nil entries in notification_references hash" do
      current.submission_email_reference = submission_email_reference

      expect(current.as_hash[:notification_references].keys).to include :submission_email_reference
      expect(current.as_hash[:notification_references].keys).not_to include :confirmation_email_reference
    end

    it "does not include nil entries in notification_ids hash" do
      current.submission_email_id = submission_email_id

      expect(current.as_hash[:notification_ids].keys).to include :submission_email_id
      expect(current.as_hash[:notification_ids].keys).not_to include :confirmation_email_id
    end
  end
end
