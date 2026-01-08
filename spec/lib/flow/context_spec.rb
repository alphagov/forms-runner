require "rails_helper"

# rubocop:disable RSpec/InstanceVariable
RSpec.describe Flow::Context do
  before do
    ActiveResource::HttpMock.disable_net_connection!
  end

  let(:pages) do
    [
      (build :page, :with_text_settings,
             id: 1,
             next_page: 2
      ),
      (build :page, :with_text_settings,
             id: 2
      ),
    ]
  end

  let(:form) do
    build(:form, :with_support,
          id: 2,
          start_page: 1,
          privacy_policy_url: "http://www.example.gov.uk/privacy_policy",
          what_happens_next_markdown: "Good things come to those that wait",
          declaration_text: "agree to the declaration",
          pages:)
  end

  [
    ["no input", { answers: [], request_step: 1 }, { next_page_slug: "2", start_id: 1, next_incomplete_page_id: "1", current_step_id: "1", previous_step_id: nil }],
    ["first question complete, request second step", { answers: [{ text: "q1 answer" }], request_step: 2 }, { next_page_slug: CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG, start_id: 1, previous_step_id: "1", next_incomplete_page_id: "2", current_step_id: "2" }],
    ["first question complete, request first step", { answers: [{ text: "q1 answer" }], request_step: 1 }, { next_page_slug: "2", start_id: 1, previous_step_id: nil, next_incomplete_page_id: "2", current_step_id: "1" }],
    ["all questions complete, request second step", { answers: [{ text: "q1 answer" }, { text: "q2 answer" }], request_step: 2 }, { next_page_slug: CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG, start_id: 1, previous_step_id: "1", next_incomplete_page_id: CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG, current_step_id: "2" }],
  ].each do |variation, input, expected_output|
    context "with #{variation}" do
      before do
        store = {}
        @context = described_class.new(form:, store:)

        current_step = @context.find_or_create(@context.next_page_slug)

        input[:answers].each do |answer|
          current_step.assign_question_attributes(answer)
          @context.save_step(current_step)
          next_page_slug = current_step.next_page_slug
          break if next_page_slug.nil?

          current_step = @context.find_or_create(next_page_slug)
        end
        @context = described_class.new(form:, store:)
        @step = @context.find_or_create(input[:request_step])
      end

      it "can visit the start page" do
        expect(@context.can_visit?("1")).to be true
      end

      it "has the correct previous step" do
        expect(@context.previous_step(@step.id)&.page_id).to eq(expected_output[:previous_step_id])
      end

      it "has the correct next incomplete step" do
        expect(@context.next_page_slug).to eq(expected_output[:next_incomplete_page_id])
      end

      describe "step" do
        it "has the right id" do
          expect(@step.id).to eq(expected_output[:current_step_id])
        end

        it "has the correct next_page_slug" do
          expect(@step.next_page_slug).to eq(expected_output[:next_page_slug])
        end
      end
    end
  end

  context "with a page which changes question type mid-journey" do
    it "does not throw an error if the question type changes when an answer has already been submitted" do
      store = {}

      # submit an answer to our page
      context1 = described_class.new(form:, store:)
      current_step = context1.find_or_create("1")
      current_step.assign_question_attributes({ text: "This is a text answer" })
      context1.save_step(current_step)

      # change the page's answer_type to another value
      form.pages[0].answer_type = "number"

      # build another context with the previous answers
      context2 = described_class.new(form:, store:)
      expect(context2.find_or_create("1").show_answer).to eq("")
    end
  end

  describe "submission details" do
    let(:context) { described_class.new(form:, store: {}) }
    let(:reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }
    let(:requested_email_confirmation) { true }

    context "when submission details have been stored" do
      before do
        context.save_submission_details(reference, requested_email_confirmation)
      end

      it "the reference number can be retrieved" do
        expect(context.get_submission_reference).to eq(reference)
      end

      it "the requested_email_confirmation value can be retrieved" do
        expect(context.requested_email_confirmation?).to eq(requested_email_confirmation)
      end

      it "can be cleared" do
        context.save_submission_details(reference, requested_email_confirmation)
        context.clear_submission_details

        expect(context.get_submission_reference).to be_nil
        expect(context.requested_email_confirmation?).to be_nil
      end
    end
  end
end
# rubocop:enable RSpec/InstanceVariable
