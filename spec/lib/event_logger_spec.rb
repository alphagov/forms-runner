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

  let(:form_log_item) do
    {
      url: "http://example.gov.uk",
      method: "GET",
      form: form.name,
    }
  end

  let(:page_log_item) do
    {
      url: "http://example.gov.uk",
      method: "GET",
      form: form.name,
      question_number: page.id,
      question_text: page.question_text,
    }
  end

  it "logs an event" do
    allow(Rails.logger).to receive(:info).at_least(:once)

    described_class.log("page_save", { test: true })

    expect(Rails.logger).to have_received(:info).with("[page_save] {\"test\":true}")
  end

  it "logs a form event" do
    allow(described_class).to receive(:log).at_least(:once)

    described_class.log_form_event(context, request, "visit")

    expect(described_class).to have_received(:log).with("form_visit", form_log_item)
  end

  context "when completing a question" do
    it "logs a page event" do
      allow(described_class).to receive(:log).at_least(:once)

      described_class.log_page_event(context, OpenStruct.new(question: page, page_number: 1), request, "page_save", nil)

      expect(described_class).to have_received(:log).with("page_save", page_log_item)
    end
  end

  context "when skipping an optional question" do
    let(:page_log_item) do
      {
        url: "http://example.gov.uk",
        method: "GET",
        form: form.name,
        question_number: page.id,
        question_text: page.question_text,
        skipped_question: "true",
      }
    end

    it "logs a page event with a question_skipped parameter" do
      allow(described_class).to receive(:log).at_least(:once)

      described_class.log_page_event(context, OpenStruct.new(question: page, page_number: 1), request, "optional_save", true)

      expect(described_class).to have_received(:log).with("optional_save", page_log_item)
    end
  end
end
