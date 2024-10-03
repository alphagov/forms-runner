require "rails_helper"

RSpec.describe Flow::Journey do
  subject(:journey) { described_class.new(form_context:, step_factory:) }

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

    context "when all pages have been completed" do
      let(:store) { { answers: { "2" => { "1" => { selection: "Option 2" }, "2" => { text: "Example text" }, "3" => { text: "More example text" } } } } }

      it "includes all pages" do
        expect(journey.completed_steps.to_json).to eq [first_step_in_journey, second_step_in_journey, third_step_in_journey].to_json
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
      let(:pages_data) { [first_page_in_form, second_page_in_form, third_page_in_form] }

      it "stops generating the completed_steps when it reaches the question with the error" do
        expect(journey.completed_steps.to_json).to eq [first_step_in_journey].to_json
      end
    end
  end
end
