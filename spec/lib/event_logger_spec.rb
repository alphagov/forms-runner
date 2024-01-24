require "rails_helper"
require_relative "../../app/lib/event_logger"

RSpec.describe EventLogger do
  let(:logging_context) do
    { some_key: "some_value" }
  end

  it "logs an event" do
    allow(Rails.logger).to receive(:info).at_least(:once)

    described_class.log({ event: "page_save", test: true })

    expect(Rails.logger).to have_received(:info).with("{\"event\":\"page_save\",\"test\":true}")
  end

  it "logs a form event" do
    allow(described_class).to receive(:log).at_least(:once)

    described_class.log_form_event(logging_context, "visit")

    expect(described_class).to have_received(:log).with(logging_context.merge({ event: "form_visit" }))
  end

  context "when completing a question" do
    it "logs a page event" do
      allow(described_class).to receive(:log).at_least(:once)

      described_class.log_page_event(logging_context, "question_text", "page_save", nil)

      expect(described_class).to have_received(:log).with(logging_context.merge(
                                                            { event: "page_save", question_text: "question_text" },
                                                          ))
    end
  end

  context "when skipping an optional question" do
    it "logs a page event with a question_skipped parameter" do
      allow(described_class).to receive(:log).at_least(:once)

      described_class.log_page_event(logging_context, "question_text", "optional_save", true)

      expect(described_class).to have_received(:log).with(logging_context.merge({
        event: "optional_save",
        question_text: "question_text",
        skipped_question: "true",
      }))
    end
  end
end
