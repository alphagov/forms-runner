require "rails_helper"

RSpec.describe Step do
  subject(:step) do
    described_class.new(
      question:,
      page:,
      form:,
      next_page_slug: "next-page",
      page_slug: "current-page",
    )
  end

  let(:question) { instance_double(Question::Text, serializable_hash: {}, attribute_names: %w[name], valid?: true) }
  let(:page) { build(:page, id: 2, position: 1, routing_conditions: []) }
  let(:form_context) { instance_double(Flow::FormContext) }
  let(:form) { build(:form, id: 3, form_slug: "test-form", pages: [page]) }

  describe "#initialize" do
    it "sets the attributes correctly" do
      expect(step.question).to eq(question)
      expect(step.page_id).to eq(2)
      expect(step.page_slug).to eq("current-page")
      expect(step.form_id).to eq(3)
      expect(step.form_slug).to eq("test-form")
      expect(step.next_page_slug).to eq("next-page")
      expect(step.page_number).to eq(1)
      expect(step.routing_conditions).to eq([])
    end
  end

  describe "#==" do
    it "returns true for steps with the same state" do
      other_step = described_class.new(
        question:,
        page:,
        form:,
        next_page_slug: "next-page",
        page_slug: "current-page",
      )
      expect(step).to eq(other_step)
    end

    it "returns false for steps with different states" do
      form = build :form, id: 4, form_slug: "other-form"
      other_step = described_class.new(
        question:,
        page:,
        form:,
        next_page_slug: "other-page",
        page_slug: "other-current-page",
      )
      expect(step == other_step).to be false
    end
  end

  describe "#state" do
    it "returns an array of instance variable values" do
      expected_state = [
        step.form,
        step.page,
        step.question,
        step.next_page_slug,
        step.page_slug,
      ]

      expect(step.state).to match_array(expected_state)
    end

    it "changes when an instance variable is modified" do
      original_state = step.state.dup
      step.form = build :form, pages: [step.page]
      expect(step.state).not_to eq(original_state)
    end
  end

  describe "#save_to_context" do
    it "saves the step to the form context" do
      expect(form_context).to receive(:save_step).with(step, {})
      step.save_to_context(form_context)
    end
  end

  describe "#load_from_context" do
    it "loads the step from the form context" do
      allow(form_context).to receive(:get_stored_answer).with(step).and_return({ name: "Test" })
      expect(question).to receive(:assign_attributes).with({ name: "Test" })
      step.load_from_context(form_context)
    end
  end

  describe "#update!" do
    it "assigns attributes and validates the question" do
      params = { name: "New Name" }
      expect(question).to receive(:assign_attributes).with(params)
      expect(question).to receive(:valid?)
      step.update!(params)
    end
  end

  describe "#params" do
    it "returns question attribute names with selection" do
      expect(step.params).to eq(["name", { selection: [] }])
    end
  end

  describe "#clear_errors" do
    it "clears errors on the question" do
      errors = instance_double(ActiveModel::Errors)
      allow(question).to receive(:errors).and_return(errors)
      expect(errors).to receive(:clear)
      step.clear_errors
    end
  end

  describe "#end_page?" do
    context "when next_page_slug is nil" do
      subject(:step) do
        described_class.new(question:, page:, form:, next_page_slug: nil, page_slug: "current-page")
      end

      it { is_expected.to be_end_page }
    end

    context "when next_page_slug is not nil" do
      it { is_expected.not_to be_end_page }
    end
  end

  describe "#next_page_slug_after_routing" do
    context "with matching routing conditions" do
      let(:question) { instance_double(Question::Selection, selection: "Yes") }
      let(:page) { build(:page, id: 2, position: 1, routing_conditions: [OpenStruct.new(answer_value: "Yes", goto_page_id: "5")]) }

      it "returns the next_page_slug" do
        expect(step.next_page_slug_after_routing).to eq("5")
      end
    end

    context "with multiple routing conditions" do
      let(:page) do
        build(:page, id: 2, position: 1, routing_conditions: [
          OpenStruct.new(answer_value: "Yes", goto_page_id: "5"),
          OpenStruct.new(answer_value: "No", goto_page_id: "6"),
        ])
      end

      let(:question) { instance_double(Question::Selection, selection: "Yes") }

      it "returns the correct goto_page_id based on selection" do
        expect(step.next_page_slug_after_routing).to eq("5")
      end
    end

    context "without matching routing conditions" do
      it "returns the next_page_slug" do
        expect(step.next_page_slug_after_routing).to eq("next-page")
      end
    end

    context "with skip_to_end condition and no goto_page_id" do
      let(:question) { instance_double(Question::Selection, selection: "Yes") }
      let(:page) { build(:page, id: 2, position: 1, routing_conditions: [OpenStruct.new(answer_value: "Yes", goto_page_id: nil, skip_to_end: true)]) }

      it "returns the check your answers page slug" do
        expect(step.next_page_slug_after_routing).to eq(CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG)
      end
    end

    context "with skip_to_end condition and goto_page_id set" do
      let(:question) { instance_double(Question::Selection, selection: "Yes") }
      let(:page) { build(:page, id: 2, position: 1, routing_conditions: [OpenStruct.new(answer_value: "Yes", goto_page_id: 7, skip_to_end: true)]) }

      it "returns the goto_page_id as a string" do
        expect(step.next_page_slug_after_routing).to eq("7")
      end
    end
  end

  describe "#repeatable?" do
    it "returns false" do
      expect(step.repeatable?).to be false
    end
  end

  describe "#skipped?" do
    it "returns true if question is optional and show_answer is blank" do
      allow(question).to receive_messages(
        is_optional?: true,
        show_answer: "",
      )
      expect(step.skipped?).to be true
    end

    it "returns false if is_optional? is false" do
      allow(question).to receive_messages(
        is_optional?: false,
        show_answer: "",
      )
      expect(step.skipped?).to be false
    end

    it "returns false if show_answer is not blank" do
      allow(question).to receive_messages(
        is_optional?: true,
        show_answer: "something",
      )
      expect(step.skipped?).to be false
    end
  end

  shared_examples "delegates to question" do |method_name|
    it "delegates #{method_name} to question" do
      expect(question).to receive(method_name)
      step.send(method_name)
    end
  end

  describe "#valid?" do
    it_behaves_like "delegates to question", :valid?
  end

  describe "#show_answer" do
    it_behaves_like "delegates to question", :show_answer
  end

  describe "#show_answer_in_email" do
    it_behaves_like "delegates to question", :show_answer_in_email
  end

  describe "#show_answer_in_csv" do
    it_behaves_like "delegates to question", :show_answer_in_csv
  end

  describe "#question_text" do
    it_behaves_like "delegates to question", :question_text
  end

  describe "#hint_text" do
    it_behaves_like "delegates to question", :hint_text
  end

  describe "#answer_settings" do
    it_behaves_like "delegates to question", :answer_settings
  end
end
