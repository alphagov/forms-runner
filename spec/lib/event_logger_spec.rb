require "rails_helper"
require_relative "../../app/lib/event_logger"

RSpec.describe EventLogger do
  let(:page) do
    build :page, :with_text_settings, id: 1, form_id: 2, routing_conditions: []
  end

  let(:form) { build :form, :with_support, id: 1, pages: [page], start_page: page.id }
  let(:context) do
    Context.new(
      form:,
      store: {},
    )
  end

  let(:request) do
    OpenStruct.new({ url: "http://example.gov.uk", method: "GET" })
  end

  before do
    allow(SessionHasher).to receive(:new).and_return(OpenStruct.new(request_to_session_hash: "session_hash"))
  end

  it "logs an event" do
    allow(Rails.logger).to receive(:info).at_least(:once)

    described_class.log({ event: "page_save", test: true })

    expect(Rails.logger).to have_received(:info).with("{\"event\":\"page_save\",\"test\":true}")
  end

  it "logs a form event" do
    allow(described_class).to receive(:log).at_least(:once)
    form_event = {
      url: "http://example.gov.uk",
      method: "GET",
      form: form.name,
      form_id: form.id,
      request_id: nil,
      event: "form_visit",
      session_id_hash: "session_hash",
    }

    described_class.log_form_event(context, request, "visit")

    expect(described_class).to have_received(:log).with(form_event)
  end

  context "when completing a question" do
    it "logs a page event" do
      allow(described_class).to receive(:log).at_least(:once)
      page_log_event = {
        url: "http://example.gov.uk",
        method: "GET",
        form: form.name,
        question_number: page.id,
        question_text: page.question_text,
        request_id: nil,
        event: "page_save",
        session_id_hash: "session_hash",
      }

      described_class.log_page_event(context, OpenStruct.new(question: page, page_number: 1), request, "page_save", nil)

      expect(described_class).to have_received(:log).with(page_log_event)
    end
  end

  context "when skipping an optional question" do
    it "logs a page event with a question_skipped parameter" do
      allow(described_class).to receive(:log).at_least(:once)
      page_log_event_with_skipped_questions = {
        url: "http://example.gov.uk",
        method: "GET",
        form: form.name,
        question_number: page.id,
        question_text: page.question_text,
        skipped_question: "true",
        request_id: nil,
        event: "optional_save",
        session_id_hash: "session_hash",
      }

      described_class.log_page_event(context, OpenStruct.new(question: page, page_number: 1), request, "optional_save", true)

      expect(described_class).to have_received(:log).with(page_log_event_with_skipped_questions)
    end
  end
end
