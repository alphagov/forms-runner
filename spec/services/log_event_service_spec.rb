require "rails_helper"

RSpec.describe LogEventService do
  let(:request) { "request" }
  let(:current_context) { OpenStruct.new(form:) }
  let(:form) { OpenStruct.new(id: 3, start_page: 1) }

  describe "#log_page_save" do
    let(:changing_answers) { true }
    let(:step) { OpenStruct.new(id: step_id, question:) }
    let(:step_id) { 2 }
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

    context "when the form is being started" do
      let(:step_id) { 1 }

      before do
        allow(EventLogger).to receive(:log_page_event).and_return(true)
        allow(Sentry).to receive(:capture_exception)
      end

      it "calls the CloudWatchService with .log_form_start" do
        allow(CloudWatchService).to receive(:log_form_start).and_return(true)

        log_event_service = described_class.new(current_context, step, request, changing_answers, answers)

        log_event_service.log_page_save

        expect(CloudWatchService).to have_received(:log_form_start).with(form_id: current_context.form.id)
      end

      it "Sentry doesn't receive an error" do
        allow(CloudWatchService).to receive(:log_form_start).and_return(true)

        log_event_service = described_class.new(current_context, step, request, changing_answers, answers)

        log_event_service.log_page_save

        expect(Sentry).not_to have_received(:capture_exception)
      end

      context "when CloudWatchService returns an error" do
        it "raises the error to Sentry" do
          allow(CloudWatchService).to receive(:log_form_start).and_raise(StandardError)

          log_event_service = described_class.new(current_context, step, request, changing_answers, answers)

          log_event_service.log_page_save

          expect(Sentry).to have_received(:capture_exception)
        end
      end
    end
  end

  describe ".log_form_submit" do
    before do
      allow(EventLogger).to receive(:log_form_event).and_return(true)
      allow(CloudWatchService).to receive(:log_form_submission).and_return(true)
    end

    context "when in preview mode" do
      it "calls the event logger with .log_form_event" do
        described_class.log_submit(current_context, request, preview: true)

        expect(EventLogger).to have_received(:log_form_event).with(
          current_context,
          request,
          "preview_submission",
        )
      end

      it "does not call the cloud watch service" do
        described_class.log_submit(current_context, request, preview: true)

        expect(CloudWatchService).not_to have_received(:log_form_submission)
      end
    end

    context "when not in preview mode" do
      it "calls the event logger with .log_form_event" do
        described_class.log_submit(current_context, request)

        expect(EventLogger).to have_received(:log_form_event).with(
          current_context,
          request,
          "submission",
        )
      end

      it "does not call the event logger for confirmation request" do
        described_class.log_submit(current_context, request)

        expect(EventLogger).not_to have_received(:log_form_event).with(
          current_context,
          request,
          "requested_email_confirmation",
        )
      end

      it "calls the cloud watch service with .log_form_submission" do
        described_class.log_submit(current_context, request)

        expect(CloudWatchService).to have_received(:log_form_submission).with(form_id: current_context.form.id)
      end

      context "when CloudWatchService returns an error" do
        it "raises the error to Sentry" do
          allow(CloudWatchService).to receive(:log_form_submission).and_raise(StandardError)
          allow(Sentry).to receive(:capture_exception)

          described_class.log_submit(current_context, request)

          expect(Sentry).to have_received(:capture_exception)
        end
      end

      context "when email confirmation is requested" do
        it "calls the event logger with .log_form_event" do
          described_class.log_submit(current_context, request, requested_email_confirmation: true)

          expect(EventLogger).to have_received(:log_form_event).with(
            current_context,
            request,
            "requested_email_confirmation",
          )
        end
      end
    end
  end

  describe ".log_form_start" do
    before do
      allow(EventLogger).to receive(:log_form_event).and_return(true)
    end

    it "calls the event logger with .log_form_event" do
      described_class.log_form_start(current_context, request)

      expect(EventLogger).to have_received(:log_form_event).with(
        current_context,
        request,
        "visit",
      )
    end
  end
end
