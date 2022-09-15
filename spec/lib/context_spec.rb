require "rails_helper"

RSpec.describe Context do
  before do
    ActiveResource::HttpMock.disable_net_connection!
  end

  let(:pages) do
    [
      Page.new({
        id: 1,
        question_text: "Question one",
        answer_type: "single_line",
        hint_text: "q1 hint",
        next_page: 2,
        question_short_name: nil,
        form: nil,
      }),
      Page.new({
        id: 2,
        question_text: "Question two",
        hint_text: "Q2 hint text",
        answer_type: "single_line",
        question_short_name: nil,
        form: nil,
      }),
    ]
  end

  let(:form) do
    f = Form.new({ id: 1, name: "Form", submission_email: "jimbo@example.gov.uk", start_page: "1", privacy_policy_url: "http://www.example.gov.uk", what_happens_next_text: "Good things come to those that wait", pages: })
    f.pages[0].form = f
    f.pages[1].form = f
    f
  end

  [
    ["no input", { answers: [], request_step: 1 }, { next_page_slug: "2", start_id: 1, next_incomplete_page_id: "1", current_step_id: 1, previous_step_id: nil }],
    ["first question complete, request second step", { answers: [{ text: "q1 answer" }], request_step: 2 }, { next_page_slug: "check_your_answers", start_id: 1, previous_step_id: 1, next_incomplete_page_id: "2", current_step_id: 2 }],
    ["first question complete, request first step", { answers: [{ text: "q1 answer" }], request_step: 1 }, { next_page_slug: "2", start_id: 1, previous_step_id: nil, next_incomplete_page_id: "2", current_step_id: 1 }],
    ["all questions complete, request second step", { answers: [{ text: "q1 answer" }, { text: "q2 answer" }], request_step: 2 }, { next_page_slug: "check_your_answers", start_id: 1, previous_step_id: 1, next_incomplete_page_id: "check_your_answers", current_step_id: 2 }],
  ].each do |variation, input, expected_output|
    context "with #{variation}" do
      before do
        store = {}
        @context = described_class.new(form:, store:)

        current_step = @context.find_or_create(@context.next_page_slug)

        input[:answers].each do |answer|
          current_step.update!(answer)
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
        expect(@context.previous_step(@step.page_slug)).to eq(expected_output[:previous_step_id])
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

  # context 'with a form with no pages' do
  #   form.pages = []
  # end
end
