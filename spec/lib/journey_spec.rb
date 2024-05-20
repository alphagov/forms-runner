require "rails_helper"
require_relative "../../app/lib/journey"

RSpec.describe Journey do
  let(:store) { {} }
  let(:form_context) { Flow::FormContext.new(store) }
  let(:step_factory) { StepFactory.new(form:) }
  let(:journey) { described_class.new(form_context:, step_factory:) }

  let(:form) do
    build(:form, :with_support,
          id: 2,
          start_page: 1,
          pages: pages_data)
  end

  let(:page_1) do
    build :page, :with_selections_settings,
          id: 1,
          next_page: 2,
          routing_conditions: [DataStruct.new(id: 1, routing_page_id: 1, check_page_id: 1, goto_page_id: 3, answer_value: "Option 1", validation_errors:)]
  end

  let(:validation_errors) { [] }

  let(:page_2) do
    build :page, :with_text_settings,
          id: 2,
          next_page: 3
  end

  let(:page_3) do
    build :page, :with_text_settings,
          id: 3
  end

  let(:pages_data) { [page_1, page_2, page_3] }

  let(:step_1) { step_factory.create_step(page_1.id.to_s).load_from_context(form_context) }
  let(:step_2) { step_factory.create_step(page_2.id.to_s).load_from_context(form_context) }
  let(:step_3) { step_factory.create_step(page_3.id.to_s).load_from_context(form_context) }

  context "when no pages have been completed" do
    it "completed_steps is empty" do
      expect(journey.completed_steps).to eq []
    end
  end

  context "when all pages have been completed" do
    let(:store) { { answers: { "2" => { "1" => { selection: "Option 2" }, "2" => { text: "Example text" }, "3" => { text: "More example text" } } } } }

    it "completed_steps includes all pages" do
      expect(journey.completed_steps.to_json).to eq [step_1, step_2, step_3].to_json
    end
  end

  context "when page has a cannot_have_goto_page_before_routing_page error" do
    let(:validation_errors) { [{ name: "cannot_have_goto_page_before_routing_page" }] }

    let(:page_1) do
      build :page, :with_text_settings,
            id: 1,
            next_page: 2
    end

    let(:page_2) do
      build :page, :with_selections_settings,
            id: 2,
            next_page: 3,
            routing_conditions: [DataStruct.new(id: 1, routing_page_id: 2, check_page_id: 2, goto_page_id: 1, answer_value: "Option 1", validation_errors:)],
            is_optional: false
    end

    let(:store) { { answers: { "2" => { "1" => { text: "Example text" }, "2" => { selection: page_2.routing_conditions.first.answer_value }, "3" => { text: "More example text" } } } } }
    let(:pages_data) { [page_1, page_2, page_3] }

    it "stops generating the completed_steps when it reaches the question with the error" do
      expect(journey.completed_steps.to_json).to eq [step_1].to_json
    end
  end
end
