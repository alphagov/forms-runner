require "rails_helper"
require_relative "../../app/lib/event_logger"

RSpec.describe EventLogger do
  let(:page) do
    Page.new({
      id: 1,
      question_text: "Question one",
      answer_type: "single_line",
      next_page: 2,
      is_optional: false,
    })
  end

  let(:context) do
    Context.new(
      form: Form.new({
        id: 1,
        name: "Form 1",
        form_slug: "form-1",
        submission_email: "jimbo@example.gov.uk",
        start_page: "1",
        privacy_policy_url: "http://www.example.gov.uk/privacy_policy",
        what_happens_next_text: "Good things come to those that wait",
        declaration_text: "agree to the declaration",
        support_email: "help@example.gov.uk",
        support_phone: "Call 01610123456\n\nThis line is only open on Tuesdays.",
        support_url: "https://example.gov.uk/contact",
        support_url_text: "Contact us",
        pages: [page],
      }),
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
      form: "Form 1",
    }
  end

  let(:page_log_item) do
    {
      url: "http://example.gov.uk",
      method: "GET",
      form: "Form 1",
      question_number: 1,
      question_text: "Question one",
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
    let(:page) do
      Page.new({
        id: 1,
        question_text: "Question one",
        answer_type: "single_line",
        next_page: 2,
        is_optional: true,
      })
    end

    let(:page_log_item) do
      {
        url: "http://example.gov.uk",
        method: "GET",
        form: "Form 1",
        question_number: 1,
        question_text: "Question one",
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
