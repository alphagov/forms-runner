require "rails_helper"

RSpec.describe Flow::Journey do
  subject(:journey) { described_class.new(form_context:, form:) }

  let(:store) { {} }
  let(:form_context) { Flow::FormContext.new(store) }
  let(:step_factory) { Flow::StepFactory.new(form:) }

  let(:form) do
    build(:form, :with_support,
          id: 2,
          start_page: 1,
          pages: pages_data)
  end

  let(:first_page_in_form) do
    build :page, :with_selections_settings,
          id: 1,
          next_page: 2,
          routing_conditions: [DataStruct.new(id: 1, routing_page_id: 1, check_page_id: 1, goto_page_id: 3, answer_value: "Option 1", validation_errors:)]
  end

  let(:validation_errors) { [] }

  let(:second_page_in_form) do
    build :page, :with_text_settings,
          id: 2,
          next_page: 3
  end

  let(:third_page_in_form) do
    build :page, :with_text_settings,
          id: 3
  end

  let(:pages_data) { [first_page_in_form, second_page_in_form, third_page_in_form] }

  let(:first_step_in_journey) { step_factory.create_step(first_page_in_form.id.to_s).load_from_context(form_context) }
  let(:second_step_in_journey) { step_factory.create_step(second_page_in_form.id.to_s).load_from_context(form_context) }
  let(:third_step_in_journey) { step_factory.create_step(third_page_in_form.id.to_s).load_from_context(form_context) }

  describe "#completed_steps" do
    context "when no pages have been completed" do
      it "is empty" do
        expect(journey.completed_steps).to eq []
      end
    end

    context "when some of the pages have been completed" do
      let(:store) { { answers: { "2" => { "1" => { selection: "Option 2" }, "2" => { text: "Example text" } } } } }

      it "includes only the pages that have been completed" do
        expect(journey.completed_steps.to_json).to eq [first_step_in_journey, second_step_in_journey].to_json
      end

      it "includes the answer data in the question pages" do
        expect(journey.completed_steps.map(&:question)).to all be_answered
      end
    end

    context "when there is a gap in the pages that have been completed" do
      let(:store) { { answers: { "2" => { "1" => { selection: "Option 2" }, "3" => { text: "More example text" } } } } }

      it "includes only the pages that have been completed before the gap" do
        expect(journey.completed_steps.to_json).to eq [first_step_in_journey].to_json
      end
    end

    context "when all pages have been completed" do
      let(:store) { { answers: { "2" => { "1" => { selection: "Option 2" }, "2" => { text: "Example text" }, "3" => { text: "More example text" } } } } }

      it "includes all pages" do
        expect(journey.completed_steps.to_json).to eq [first_step_in_journey, second_step_in_journey, third_step_in_journey].to_json
      end

      it "includes the answer data in the question pages" do
        expect(journey.completed_steps.map(&:question)).to all be_answered
      end
    end

    context "when a question is optional" do
      let(:second_page_in_form) do
        build :page, :with_text_settings,
              is_optional: true,
              id: 2,
              next_page: 3
      end

      context "and all questions have been answered" do
        let(:store) { { answers: { "2" => { "1" => { selection: "Option 2" }, "2" => { text: "Example text" }, "3" => { text: "More example text" } } } } }

        it "includes all pages" do
          expect(journey.completed_steps.to_json).to eq [first_step_in_journey, second_step_in_journey, third_step_in_journey].to_json
        end
      end

      context "and the optional question has not been visited" do
        let(:store) { { answers: { "2" => { "1" => { selection: "Option 2" }, "3" => { text: "More example text" } } } } }

        it "includes only pages that have been completed before the optional question" do
          expect(journey.completed_steps.to_json).to eq [first_step_in_journey].to_json
        end
      end

      context "and the optional question has a blank answer" do
        let(:store) { { answers: { "2" => { "1" => { selection: "Option 2" }, "2" => { text: "" }, "3" => { text: "More example text" } } } } }

        it "includes all pages" do
          expect(journey.completed_steps.to_json).to eq [first_step_in_journey, second_step_in_journey, third_step_in_journey].to_json
        end
      end
    end

    context "when a page is repeatable" do
      let(:second_page_in_form) do
        build :page, :with_text_settings,
              is_repeatable: true,
              id: 2,
              next_page: 3
      end

      context "when all pages have been completed" do
        let(:store) { { answers: { "2" => { "1" => { selection: "Option 2" }, "2" => [{ text: "Example text" }], "3" => { text: "More example text" } } } } }

        it "includes all pages" do
          expect(journey.completed_steps.to_json).to eq [first_step_in_journey, second_step_in_journey, third_step_in_journey].to_json
        end

        it "includes the answer data in the question pages" do
          expect(journey.completed_steps.map(&:question)).to all be_answered
        end

        context "and the repeatable question has been answered more than once" do
          let(:store) { { answers: { "2" => { "1" => { selection: "Option 2" }, "2" => [{ text: "Example text" }, { text: "Different example text" }], "3" => { text: "More example text" } } } } }

          it "includes all pages once each" do
            expect(journey.completed_steps.to_json).to eq [first_step_in_journey, second_step_in_journey, third_step_in_journey].to_json
          end
        end

        context "but the answer store does not have data in the format expected for the repeatable question" do
          let(:store) { { answers: { "2" => { "1" => { selection: "Option 2" }, "2" => { text: "Example text" }, "3" => { text: "More example text" } } } } }

          it "includes only pages before the repeatable question" do
            expect(journey.completed_steps.to_json).to eq [first_step_in_journey].to_json
          end
        end
      end
    end

    context "when a page has a routing condition" do
      context "and the page answer matches the routing condition" do
        let(:store) { { answers: { "2" => { "1" => { selection: "Option 1" }, "3" => { text: "More example text" } } } } }

        it "includes only pages in the matched route" do
          expect(journey.completed_steps.to_json).to eq [first_step_in_journey, third_step_in_journey].to_json
        end

        it "includes the answer data in the question pages" do
          expect(journey.completed_steps.map(&:question)).to all be_answered
        end

        context "when there are answers to questions not in the matched route" do
          let(:store) { { answers: { "2" => { "1" => { selection: "Option 1" }, "2" => { text: "Example text" }, "3" => { text: "More example text" } } } } }

          it "includes only pages in the matched route" do
            expect(journey.completed_steps.to_json).to eq [first_step_in_journey, third_step_in_journey].to_json
          end
        end
      end
    end

    context "when the answer store has data that does not match the type expected by the question" do
      let(:store) { { answers: { "2" => { "1" => { selection: "Option 2" }, "2" => { text: "Example text" }, "3" => { selection: "Option 1" } } } } }

      it "includes only pages before the answer with the wrong type" do
        expect(journey.completed_steps.to_json).to eq [first_step_in_journey, second_step_in_journey].to_json
      end

      it "includes the answer data in the question pages" do
        expect(journey.completed_steps.map(&:question)).to all be_answered
      end
    end

    context "when page has a cannot_have_goto_page_before_routing_page error" do
      let(:validation_errors) { [{ name: "cannot_have_goto_page_before_routing_page" }] }

      let(:first_page_in_form) do
        build :page, :with_text_settings,
              id: 1,
              next_page: 2
      end

      let(:second_page_in_form) do
        build :page, :with_selections_settings,
              id: 2,
              next_page: 3,
              routing_conditions: [DataStruct.new(id: 1, routing_page_id: 2, check_page_id: 2, goto_page_id: 1, answer_value: "Option 1", validation_errors:)],
              is_optional: false
      end

      let(:store) { { answers: { "2" => { "1" => { text: "Example text" }, "2" => { selection: second_page_in_form.routing_conditions.first.answer_value }, "3" => { text: "More example text" } } } } }

      it "stops generating the completed_steps when it reaches the question with the error" do
        expect(journey.completed_steps.to_json).to eq [first_step_in_journey].to_json
      end
    end
  end

  describe "#all_steps" do
    context "when some questions have not been answered" do
      let(:store) { { answers: { "2" => { "1" => { selection: "Option 2" }, "2" => { text: "Example text" } } } } }

      it "creates steps for the unanswered questions" do
        expect(journey.all_steps.length).to eq(3)
        expect(journey.all_steps.to_json).to eq [first_step_in_journey, second_step_in_journey, third_step_in_journey].to_json
      end
    end
  end
end
