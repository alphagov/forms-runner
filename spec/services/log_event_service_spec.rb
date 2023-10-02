require "rails_helper"

RSpec.describe LogEventService do
  let(:request) { "request" }
  let(:current_context) { "current_context" }

  describe "#log_page_save" do
    let(:changing_answers) { true }
    let(:step) { OpenStruct.new(question:) }
    let(:question) { OpenStruct.new(is_optional?: true) }
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

  describe ".log_form_submit" do
    let(:current_context) { OpenStruct.new(form:) }
    let(:form) { OpenStruct.new(id: 1) }

    it "calls the event logger with .log_form_event" do
      allow(CloudWatchService).to receive(:log_form_submission).and_return(true)
      allow(EventLogger).to receive(:log_form_event).and_return(true)

      described_class.log_submit(current_context, request)

      expect(EventLogger).to have_received(:log_form_event).with(
        current_context,
        request,
        "submission",
      )
    end

    it "calls the cloud watch service with .log_form_submission" do
      allow(CloudWatchService).to receive(:log_form_submission).and_return(true)
      allow(EventLogger).to receive(:log_form_event).and_return(true)

      described_class.log_submit(current_context, request)

      expect(CloudWatchService).to have_received(:log_form_submission).with(form_id: current_context.form.id)
    end
  end
end
