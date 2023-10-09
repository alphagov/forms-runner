require "rails_helper"

RSpec.describe FormSubmissionService do
  let(:service) { described_class.call(current_context:, reference: "for-my-ref", preview_mode:) }
  let(:form) { OpenStruct.new(id: 1, name: "Form 1", submission_email: "testing@gov.uk") }
  let(:current_context) { OpenStruct.new(form:, completed_steps: [step]) }
  let(:step) { OpenStruct.new({ question_text: "What is the meaning of life?", show_answer_in_email: "42" }) }
  let(:preview_mode) { false }

  describe "#submit_form_to_processing_team" do
    it "calls FormSubmissionMailer" do
      freeze_time do
        delivery = double
        expect(delivery).to receive(:deliver_now).with(no_args)
        allow(FormSubmissionMailer).to receive(:email_completed_form).and_return(delivery)

        service.submit_form_to_processing_team
        expect(FormSubmissionMailer).to have_received(:email_completed_form).with(
          { title: "Form 1",
            text_input: "# What is the meaning of life?\n42\n",
            reference: "for-my-ref",
            timestamp: Time.zone.now,
            submission_email: "testing@gov.uk",
            preview_mode: false },
        ).once
      end
    end

    context "when the mailer raises an exception" do
      exceptions = [
        [Notifications::Client::BadRequestError, "BadRequest"],
        [Notifications::Client::AuthError, "AuthError"],
        [Notifications::Client::NotFoundError, "NotFoundError"],
        [Notifications::Client::RateLimitError, "RateLimitError"],
        [Notifications::Client::ClientError, "ClientError"],
      ]

      exceptions.each do |exception, error_message|
        it "includes the email body in the #{exception} exception message" do
          mailer = double

          allow(mailer).to receive(:deliver_now).and_raise(exception.new(OpenStruct.new(code: 500, body: {
            status_code: 500,
            errors: [{ error: error_message, message: "" }],
          }.to_json)))

          allow(FormSubmissionMailer).to receive(:email_completed_form).and_return(mailer)

          expect { service.submit_form_to_processing_team }.to raise_error(FormSubmissionService::SubmissionError).with_message("Notify failed to send email. Notify code: 500")
        end
      end

      it "does not catch non-Notify exceptions" do
        mailer = double
        allow(mailer).to receive(:deliver_now).and_raise(StandardError, "some other error")
        allow(FormSubmissionMailer).to receive(:email_completed_form).and_return(mailer)
        expect { service.submit_form_to_processing_team }.to raise_error(StandardError).with_message("some other error")
      end
    end

    describe "validations" do
      context "when form has no submission email" do
        let(:form) { OpenStruct.new(id: 1, form_name: "Form 1", submission_email: nil, steps: [step]) }

        it "raises an error" do
          expect { service.submit_form_to_processing_team }.to raise_error("Form id(1) is missing a submission email address")
        end
      end

      context "when current context has no completed steps (i.e questions/answers)" do
        let(:current_context) { OpenStruct.new(form:, steps: []) }
        let(:result) { service.submit_form_to_processing_team }

        it "raises an error" do
          expect { result }.to raise_error("Form id(1) has no completed steps i.e questions/answers to include in submission email")
        end
      end
    end

    context "when form being submitted is from previewed form" do
      let(:preview_mode) { true }

      it "calls FormSubmissionMailer" do
        freeze_time do
          delivery = double
          expect(delivery).to receive(:deliver_now).with(no_args)
          allow(FormSubmissionMailer).to receive(:email_completed_form).and_return(delivery)

          service.submit_form_to_processing_team
          expect(FormSubmissionMailer).to have_received(:email_completed_form).with(
            { title: "Form 1",
              text_input: "# What is the meaning of life?\n42\n",
              reference: "for-my-ref",
              timestamp: Time.zone.now,
              submission_email: "testing@gov.uk",
              preview_mode: true },
          ).once
        end
      end

      describe "validations" do
        context "when form has no submission email" do
          let(:form) { OpenStruct.new(id: 1, form_name: "Form 1", submission_email: nil, steps: [step]) }

          it "does not raise an error" do
            expect { service.submit_form_to_processing_team }.not_to raise_error
          end

          it "does not call the FormSubmissionMailer" do
            allow(FormSubmissionMailer).to receive(:email_completed_form).at_least(:once)

            service.submit_form_to_processing_team

            expect(FormSubmissionMailer).not_to have_received(:email_completed_form)
          end
        end

        context "when from has no steps (i.e questions/answers)" do
          let(:current_context) { OpenStruct.new(form:, steps: []) }
          let(:result) { service.submit_form_to_processing_team }

          it "raises an error" do
            expect { result }.to raise_error("Form id(1) has no completed steps i.e questions/answers to include in submission email")
          end
        end
      end
    end
  end

  describe "FormSubmissionService::NotifyTemplateBodyFilter" do
    let(:notify_template_body_filter) { FormSubmissionService::NotifyTemplateBodyFilter.new }

    describe "#build_question_answers_section" do
      let(:form) { OpenStruct.new(completed_steps: [step]) }

      let(:step) { OpenStruct.new({ question_text: "What is the meaning of life?", show_answer_in_email: "42" }) }

      it "returns combined title and answer" do
        expect(notify_template_body_filter.build_question_answers_section(form)).to eq "# What is the meaning of life?\n42\n"
      end

      context "when there is more than one step" do
        let(:form) { OpenStruct.new(completed_steps: [step, step]) }

        it "contains a horizontal rule between each step" do
          expect(notify_template_body_filter.build_question_answers_section(form)).to include "\n\n---\n\n"
        end
      end
    end

    describe "#prep_question_title" do
      it "returns markdown heading on its own line" do
        klass = notify_template_body_filter
        ["Hello", "3.4 Question", "-23.4 Negative headings", "\n\n # 4.5.6"].each do |title|
          expect(klass.prep_question_title(title)).to eq "# #{title}\n"
        end
      end
    end

    describe "#prep_answer_text" do
      it "returns escaped answer" do
        [
          { input: "Hello", output: "Hello" },
          { input: "3.4 Question", output: "3\\.4 Question" },
          { input: "-23.4 answer", output: "\\-23\\.4 answer" },
          { input: "4.5.6", output: "4\\.5\\.6" },
          { input: "\n\n# Test \n\n## Test 2", output: "\\# Test\n\n\\#\\# Test 2" },
          { input: "\n\n```# Test 3\n\n## Test 4", output: "\\`\\`\\`\\# Test 3\n\n\\#\\# Test 4" }, # escapes ```
          { input: "\n\n\n\n\n```# Test \n\n\n\n\n\n## Test 3\n\n\n\n", output: "\\`\\`\\`\\# Test\n\n\\#\\# Test 3" },
          { input: "test https://example.org # more text 19.5\n\nA new paragraph.", output: "test https://example.org \\# more text 19\\.5\n\nA new paragraph\\." },
          { input: "test https://example.org # more text 19.5\n\nA new paragraph.\n\n# another link http://gov.uk", output: "test https://example.org \\# more text 19\\.5\n\nA new paragraph\\.\n\n\\# another link http://gov.uk" },
          { input: "not a title\n====", output: "not a title\n\\_\\_\\_\\_" },
          { input: "a normal sentence: 10 = 5 + 5", output: "a normal sentence: 10 = 5 \\+ 5" },
          { input: "    paragraph 1\n\n\n\n\n\n\n\n\n\n\n\n\n Another Paragraph with trailing space     \n\n\n\n\n", output: "paragraph 1\n\nAnother Paragraph with trailing space" },

        ].each do |test_case|
          expect(notify_template_body_filter.prep_answer_text(test_case[:input])).to eq test_case[:output]
        end
      end

      context "when answer is blank i.e skipped" do
        it "returns the blank answer text" do
          expect(notify_template_body_filter.prep_answer_text("")).to eq "\\[This question was skipped\\]"
        end
      end
    end
  end
end
