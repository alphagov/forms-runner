require "rails_helper"

RSpec.describe LogEventService do
  describe "#log_page_save" do
    let(:changing_answers) { true }
    let(:step) { OpenStruct.new(question:) }
    let(:question) { OpenStruct.new(is_optional?: true) }
    let(:request) { "request" }
    let(:current_context) { "current_context" }
    let(:answers) { { "name": "John" } }

    it "calls the event logger with log_page_event" do
      allow(EventLogger).to receive(:log_page_event).and_return(true)

      log_event_service = described_class.new(current_context, step, request, changing_answers, answers)

      log_event_service.log_page_save
      expect(EventLogger).to have_received(:log_page_event).with(
        current_context,
        step,
        request,
        "change_answer_optional_save",
        false,
      )
    end
  end
end
