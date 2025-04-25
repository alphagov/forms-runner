require "rails_helper"

RSpec.describe Flow::Journey do
  subject(:journey) { described_class.new(answer_store:, form:) }

  let(:store) { {} }
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

  let(:first_step_in_journey) { step_factory.create_step(first_page_in_form.id.to_s).load_from_store(answer_store) }
  let(:second_step_in_journey) { step_factory.create_step(second_page_in_form.id.to_s).load_from_store(answer_store) }
  let(:third_step_in_journey) { step_factory.create_step(third_page_in_form.id.to_s).load_from_store(answer_store) }

  describe "#completed_steps" do
    context "when answers are loaded from the session" do
      let(:answer_store) { Store::SessionAnswerStore.new(store, form.id) }

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

      context "when there are multiple files with the same name" do
        let(:first_page_in_form) { build(:page, answer_type: "file", id: 1, next_page: 2) }
        let(:second_page_in_form) { build(:page, answer_type: "file", id: 2, next_page: 3) }
        let(:third_page_in_form) { build(:page, answer_type: "file", id: 3, next_page: 4) }
        let(:fourth_page_in_form) { build(:page, answer_type: "file", id: 4) }
        let(:pages_data) { [first_page_in_form, second_page_in_form, third_page_in_form, fourth_page_in_form] }
        let(:store) do
          {
            answers: {
              "2" =>
                {
                  "1" => { uploaded_file_key: "key1", original_filename: "file1", filename_suffix: "" },
                  "2" => { uploaded_file_key: "key2", original_filename: "a different filename", filename_suffix: "" },
                  "3" => { uploaded_file_key: "key3", original_filename: "file1", filename_suffix: "" },
                  "4" => { uploaded_file_key: "key4", original_filename: "file1", filename_suffix: "" },
                },
            },
          }
        end

        it "does not add a numerical suffix to the first instance of a filename" do
          expect(journey.all_steps[0].question.filename_suffix).to eq("")
          expect(journey.all_steps[1].question.filename_suffix).to eq("")
        end

        it "adds a numerical suffix to any files with duplicate filenames" do
          expect(journey.all_steps[2].question.filename_suffix).to eq("_1")
          expect(journey.all_steps[3].question.filename_suffix).to eq("_2")
        end
      end

      context "when there are multiple files with different names that are the same after truncation" do
        let(:first_page_in_form) { build(:page, answer_type: "file", id: 1, next_page: 2) }
        let(:second_page_in_form) { build(:page, answer_type: "file", id: 2, next_page: 3) }
        let(:third_page_in_form) { build(:page, answer_type: "file", id: 3, next_page: 4) }
        let(:fourth_page_in_form) { build(:page, answer_type: "file", id: 4) }
        let(:pages_data) { [first_page_in_form, second_page_in_form, third_page_in_form, fourth_page_in_form] }
        let(:store) do
          {
            answers: {
              "2" =>
                {
                  "1" => { uploaded_file_key: "key1", original_filename: "this_is_an_incredibly_long_filename_that_will_surely_have_to_be_truncated_somewhere_near_the_end_version_one", filename_suffix: "" },
                  "2" => { uploaded_file_key: "key2", original_filename: "a different filename", filename_suffix: "" },
                  "3" => { uploaded_file_key: "key3", original_filename: "this_is_an_incredibly_long_filename_that_will_surely_have_to_be_truncated_somewhere_near_the_end_version_two", filename_suffix: "" },
                  "4" => { uploaded_file_key: "key4", original_filename: "this_is_an_incredibly_long_filename_that_will_surely_have_to_be_truncated_somewhere_near_the_end_version_three", filename_suffix: "" },
                },
            },
          }
        end

        it "does not add a numerical suffix to the first instance of a filename" do
          expect(journey.all_steps[0].question.filename_suffix).to eq("")
          expect(journey.all_steps[1].question.filename_suffix).to eq("")
        end

        it "adds a numerical suffix to any files which would have duplicate filenames after truncation" do
          expect(journey.all_steps[2].question.filename_suffix).to eq("_1")
          expect(journey.all_steps[3].question.filename_suffix).to eq("_2")
        end
      end
    end

    context "when answers are loaded from the database" do
      let(:answer_store) { Store::DatabaseAnswerStore.new(answers) }

      context "when some of the pages have been completed" do
        let(:answers) { { "1" => { selection: "Option 2" }, "2" => { text: "Example text" } } }

        it "includes only the pages that have been completed" do
          expect(journey.completed_steps.to_json).to eq [first_step_in_journey, second_step_in_journey].to_json
        end

        it "includes the answer data in the question pages" do
          expect(journey.completed_steps.map(&:question)).to all be_answered
        end
      end
    end
  end

  describe "#all_steps" do
    context "when answers are loaded from the session" do
      let(:answer_store) { Store::SessionAnswerStore.new(store, form.id) }

      context "when some questions have not been answered" do
        let(:store) { { answers: { "2" => { "1" => { selection: "Option 2" }, "2" => { text: "Example text" } } } } }

        it "creates steps for the unanswered questions" do
          expect(journey.all_steps.length).to eq(3)
          expect(journey.all_steps.to_json).to eq [first_step_in_journey, second_step_in_journey, third_step_in_journey].to_json
        end
      end
    end

    context "when answers are loaded from the database" do
      let(:answer_store) { Store::DatabaseAnswerStore.new(answers) }

      context "when some questions have not been answered" do
        let(:answers) { { "1" => { selection: "Option 2" }, "2" => { text: "Example text" } } }

        it "creates steps for the unanswered questions" do
          expect(journey.all_steps.length).to eq(3)
          expect(journey.all_steps.to_json).to eq [first_step_in_journey, second_step_in_journey, third_step_in_journey].to_json
        end
      end
    end
  end

  describe "#completed_file_upload_questions" do
    let(:first_page_in_form) { build(:page, answer_type: "file", id: 1, next_page: 2) }
    let(:second_page_in_form) { build(:page, answer_type: "file", id: 2, next_page: 3) }
    let(:third_page_in_form) { build(:page, answer_type: "file", id: 3, next_page: 4) }
    let(:fourth_page_in_form) { build(:page, :with_text_settings, id: 4) }
    let(:pages_data) { [first_page_in_form, second_page_in_form, third_page_in_form, fourth_page_in_form] }

    let(:answer_store) { Store::SessionAnswerStore.new(store, form.id) }
    let(:store) do
      {
        answers: {
          "2" =>
            {
              "1" => { uploaded_file_key: "key1", original_filename: "file1" },
              "2" => { original_filename: "" },
              "3" => { uploaded_file_key: "key2", original_filename: "file2" },
              "4" => { text: "Example text" },
            },
        },
      }
    end

    it "returns the answered file upload questions" do
      completed_file_upload_questions = journey.completed_file_upload_questions
      expect(completed_file_upload_questions.length).to eq 2
      expect(completed_file_upload_questions.first.uploaded_file_key).to eq "key1"
      expect(completed_file_upload_questions.second.uploaded_file_key).to eq "key2"
    end
  end
end
