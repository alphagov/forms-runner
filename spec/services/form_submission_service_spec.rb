require "rails_helper"

RSpec.describe FormSubmissionService do
  let(:service) { described_class.call(current_context:, email_confirmation_form:, preview_mode:) }
  let(:form) do
    build(:form,
          id: 1,
          name: "Form 1",
          what_happens_next_text:,
          support_email:,
          support_phone:,
          support_url:,
          support_url_text:,
          submission_email: "testing@gov.uk")
  end
  let(:what_happens_next_text) { "We usually respond to applications within 10 working days." }
  let(:support_email) { Faker::Internet.email(domain: "example.gov.uk") }
  let(:support_phone) { Faker::Lorem.paragraph(sentence_count: 2, supplemental: true, random_sentences_to_add: 4) }
  let(:support_url) { Faker::Internet.url(host: "gov.uk") }
  let(:support_url_text) { Faker::Lorem.sentence(word_count: 1, random_words_to_add: 4) }

  let(:current_context) { OpenStruct.new(form:, completed_steps: [step], support_details: OpenStruct.new(call_back_url: "http://gov.uk")) }
  let(:step) { OpenStruct.new({ question_text: "What is the meaning of life?", show_answer_in_email: "42" }) }
  let(:preview_mode) { false }
  let(:email_confirmation_form) { build :email_confirmation_form_opted_in }

  describe "#submit" do
    it "calls submit_form_to_processing_team method" do
      expect(service).to receive(:submit_form_to_processing_team).once
      service.submit
    end

    it "does not call submit_confirmation_email_to_user" do
      expect(service).not_to receive(:submit_confirmation_email_to_user)
      service.submit
    end

    describe "when email_confirmation feature is enabled", feature_email_confirmations_enabled: true do
      it "calls submit_confirmation_email_to_user" do
        expect(service).to receive(:submit_confirmation_email_to_user).once
        service.submit
      end
    end
  end

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
            reference: email_confirmation_form.notify_reference,
            timestamp: Time.zone.now,
            submission_email: "testing@gov.uk",
            preview_mode: false },
        ).once
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
              reference: email_confirmation_form.notify_reference,
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

  describe "#submit_confirmation_email_to_user" do
    it "calls FormSubmissionConfirmationMailer" do
      freeze_time do
        delivery = double
        expect(delivery).to receive(:deliver_now).with(no_args)
        allow(FormSubmissionConfirmationMailer).to receive(:send_confirmation_email).and_return(delivery)

        service.submit_confirmation_email_to_user
        expect(FormSubmissionConfirmationMailer).to have_received(:send_confirmation_email).with(
          { title: "Form 1",
            what_happens_next_text: form.what_happens_next,
            support_contact_details: contact_support_details_format,
            submission_timestamp: Time.zone.now,
            preview_mode:,
            confirmation_email_address: email_confirmation_form.confirmation_email_address },
        ).once
      end
    end

    context "when user does not want a confirmation email" do
      let(:email_confirmation_form) { build :email_confirmation_form }

      it "does not call FormSubmissionConfirmationMailer" do
        allow(FormSubmissionConfirmationMailer).to receive(:send_confirmation_email)

        service.submit_confirmation_email_to_user
        expect(FormSubmissionConfirmationMailer).not_to have_received(:send_confirmation_email)
      end

      it "returns nil" do
        expect(service.submit_confirmation_email_to_user).to be_nil
      end
    end

    context "when form is draft" do
      context "when form does not have 'what happens next details'" do
        let(:what_happens_next_text) { nil }

        it "does not call FormSubmissionConfirmationMailer" do
          allow(FormSubmissionConfirmationMailer).to receive(:send_confirmation_email)

          service.submit_confirmation_email_to_user
          expect(FormSubmissionConfirmationMailer).not_to have_received(:send_confirmation_email)
        end

        it "returns nil" do
          expect(service.submit_confirmation_email_to_user).to be_nil
        end
      end

      context "when form does not have any support details " do
        let(:support_email) { nil }
        let(:support_phone) { nil }
        let(:support_url) { nil }
        let(:support_url_text) { nil }

        it "does not call FormSubmissionConfirmationMailer" do
          allow(FormSubmissionConfirmationMailer).to receive(:send_confirmation_email)

          service.submit_confirmation_email_to_user
          expect(FormSubmissionConfirmationMailer).not_to have_received(:send_confirmation_email)
        end

        it "returns nil" do
          expect(service.submit_confirmation_email_to_user).to be_nil
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

private

  def contact_support_details_format
    phone_number = "#{form.support_phone}\n\n[#{I18n.t('support_details.call_charges')}](http://gov.uk)"
    email = "[#{form.support_email}](mailto:#{form.support_email})"
    online = "[#{form.support_url_text}](#{form.support_url})"
    [phone_number, email, online].compact_blank.join("\n\n")
  end
end
