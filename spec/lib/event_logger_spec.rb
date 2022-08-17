require "rails_helper"
require_relative "../../app/lib/event_logger"

RSpec.describe EventLogger do
  let(:page) do
    Page.new({
      id: 1,
      question_text: "Question one",
      answer_type: "single_line",
      next: 2,
      question_short_name: nil,
    })
  end

  let(:context) { Context.new(form: Form.new({ id: 1, name: "Form", submission_email: "jimbo@example.gov.uk", start_page: "1", pages: [page] }), store: {}) }

  let(:request) do
    OpenStruct.new({ url: "http://example.gov.uk", method: "GET", user_agent: "agent" })
  end

  let(:form_log_item) do
    {
      url: "http://example.gov.uk",
      method: "GET",
      form: "Form",
      user_agent: "agent",
    }
  end

  let(:page_log_item) do
    {
      url: "http://example.gov.uk",
      method: "GET",
      form: "Form",
      question_text: "Question one",
      user_agent: "agent",
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

  it "logs a page event" do
    allow(described_class).to receive(:log).at_least(:once)

    described_class.log_page_event(context, OpenStruct.new(question: page), request, "page_save")

    expect(described_class).to have_received(:log).with("page_save", page_log_item)
  end
end
