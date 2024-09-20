require "rails_helper"

RSpec.describe Api::V1::Converter do
  subject(:converter) { described_class.new }

  describe "#to_api_v1_form_snapshot" do
    let(:form_document) { { "form_id" => 1, "name" => "Test form", "steps" => [] } }
    let(:form_snapshot) { converter.to_api_v1_form_snapshot(form_document) }

    it "takes a v2 form document and turns it into a form snapshot" do
      expect(form_snapshot).to be_a Hash
    end

    it "includes all the form document data" do
      expect(form_snapshot).to include(**form_document.except("form_id", "steps"))
    end

    it "prepends the form id" do
      expect(form_snapshot).to include "id" => 1
    end

    context "when the form document does not have steps" do
      let(:form_document) { { "form_id" => 1, "name" => "Test form" } }

      it "does not raise error" do
        expect {
          converter.to_api_v1_form_snapshot(form_document)
        }.not_to raise_error
      end

      it "has an empty collection of pages" do
        expect(form_snapshot).to include "pages" => []
      end
    end

    context "when the form document has steps" do
      let(:form_document) { { "form_id" => 1, "name" => "Test form", "steps" => steps } }
      let(:steps) do
        [
          { "id" => 10, "next_step_id" => 11 },
          { "id" => 11, "next_step_id" => 12 },
          { "id" => 12 },
        ]
      end

      it "transforms steps to pages" do
        expect(form_snapshot).not_to include "steps"
        expect(form_snapshot).to include "pages"
      end

      it "has a page for each step" do
        expect(form_snapshot["pages"].pluck("id"))
          .to eq form_document["steps"].pluck("id")
      end

      it "links each page to the next" do
        pages = form_snapshot["pages"]
        pages.each_with_index do |page, index|
          next_page = pages.fetch(index + 1, {})
          expect(page).to include "next_page" => next_page["id"]
        end
      end
    end
  end

  describe "#to_api_v1_page" do
    let(:page) { converter.to_api_v1_page(step) }
    let(:step) do
      {
        "id" => 18,
        "next_step_id" => 19,
        "created_at" => "2024-08-02T08:54:04.908Z",
        "updated_at" => "2024-08-02T08:54:04.908Z",
        "form_id" => 8,
        "position" => 1,
        "type" => "question_page",
        "data" => {
          "question_text" => "Do you want to remain anonymous?",
          "hint_text" => "",
          "answer_type" => "selection",
          "is_optional" => false,
          "answer_settings" => {
            "only_one_option" => "true",
            "selection_options" => [
              {
                "name" => "Yes",
              },
              {
                "name" => "No",
              },
            ],
          },
          "page_heading" => nil,
          "guidance_markdown" => nil,
          "is_repeatable" => false,
        },
        "routing_conditions" => [
          {
            "id" => 3,
            "check_step_id" => 18,
            "routing_step_id" => 18,
            "goto_step_id" => nil,
            "answer_value" => "Yes",
            "created_at" => "2024-08-02T08:54:07.479Z",
            "updated_at" => "2024-08-02T08:54:07.479Z",
            "skip_to_end" => true,
            "validation_errors" => [],
          },
        ],
      }
    end

    it "includes all the step data" do
      expect(page).to include(**step.except("next_step_id", "form_id", "data", "type", "created_at", "updated_at"))
    end

    it "include routing conditions in page" do
      expect(page).to include "routing_conditions" => step["routing_conditions"]
    end

    it "includes data for questions in page" do
      expect(page).to include(**step["data"])
    end
  end
end
