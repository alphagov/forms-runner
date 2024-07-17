require "rails_helper"
require_relative "../../app/lib/event_logger"

RSpec.describe EventLogger do
  let(:logging_context) do
    { some_key: "some_value" }
  end

  it "logs a form event" do
    allow(Rails.logger).to receive(:info).at_least(:once)

    described_class.log_form_event("visit", logging_context)

    expect(Rails.logger).to have_received(:info).with("Form event", logging_context.merge({ event: "form_visit" }))
  end

  context "when completing a question" do
    it "logs a page event" do
      allow(Rails.logger).to receive(:info).at_least(:once)

      described_class.log_page_event("page_save", "question_text", nil)

      expect(Rails.logger).to have_received(:info).with("Form event",
                                                        { event: "page_save",
                                                          question_text: "question_text" })
    end
  end

  context "when skipping an optional question" do
    it "logs a page event with a question_skipped parameter" do
      allow(Rails.logger).to receive(:info).at_least(:once)

      described_class.log_page_event("optional_save", "question_text", true)

      expect(Rails.logger).to have_received(:info).with("Form event",
                                                        { event: "optional_save",
                                                          question_text: "question_text",
                                                          skipped_question: "true" })
    end
  end
end
