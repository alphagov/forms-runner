require "rails_helper"

RSpec.describe Question::Selection, type: :model do
  subject(:question) { described_class.new({}, options) }

  let(:options) do
    {
      is_optional:,
      answer_settings: OpenStruct.new({
        only_one_option:,
        selection_options: [OpenStruct.new({ name: "option 1" }), OpenStruct.new({ name: "option 2" })],
      }),
      question_text:,
    }
  end
  let(:question_text) { Faker::Lorem.question }

  context "when the selection question is a checkbox" do
    let(:only_one_option) { "false" }
    let(:is_optional) { false }

    it_behaves_like "a question model"

    context "when created without attriibutes" do
      it "returns invalid" do
        expect(question).not_to be_valid
        expect(question.errors[:selection]).to include(I18n.t("activemodel.errors.models.question/selection.attributes.selection.checkbox_blank"))
      end

      it "shows as a blank string" do
        expect(question.show_answer).to eq ""
      end

      it "returns a hash with an blank value for show_answer_in_csv" do
        expect(question.show_answer_in_csv).to eq(Hash[question_text, ""])
      end
    end

    context "when selection is blank" do
      before do
        question.selection = [""]
      end

      it "returns invalid" do
        expect(question).not_to be_valid
        expect(question.errors[:selection]).to include(I18n.t("activemodel.errors.models.question/selection.attributes.selection.checkbox_blank"))
      end

      it "shows as a blank string" do
        expect(question.show_answer).to eq ""
      end

      it "returns a hash with an blank value for show_answer_in_csv" do
        expect(question.show_answer_in_csv).to eq(Hash[question_text, ""])
      end
    end

    context "when selection has a value" do
      before do
        question.selection = %w[something]
      end

      it "shows the answer" do
        expect(question.show_answer).to eq("something")
      end

      it "shows the answer in show_answer_in_csv" do
        expect(question.show_answer_in_csv).to eq(Hash[question_text, "something"])
      end
    end

    it "returns invalid when selection is not one of the options" do
      question.selection = ["option 1000"]
      expect(question).not_to be_valid
      expect(question.errors[:selection]).to include(I18n.t("activemodel.errors.models.question/selection.attributes.selection.inclusion"))
    end

    it "returns valid with one item selected" do
      question.selection = ["option 1"]
      expect(question).to be_valid
      expect(question.errors[:selection]).to be_empty
    end

    it "returns valid with two items selected" do
      question.selection = ["option 1", "option 2"]
      expect(question).to be_valid
      expect(question.errors[:selection]).to be_empty
    end

    it "calculates allow_multiple_answers correctly" do
      expect(question.allow_multiple_answers?).to be true
    end

    context "when question is optional" do
      let(:is_optional) { true }

      context "when selection is blank" do
        before do
          question.selection = [""]
        end

        it "returns invalid with blank selection" do
          expect(question).not_to be_valid
          expect(question.errors[:selection]).to include(I18n.t("activemodel.errors.models.question/selection.attributes.selection.both_none_and_value_selected"))
        end

        it "shows as a blank string" do
          expect(question.show_answer).to eq ""
        end

        it "returns a hash with an blank value for show_answer_in_csv" do
          expect(question.show_answer_in_csv).to eq(Hash[question_text, ""])
        end
      end

      it "returns valid with none of the above selected" do
        question.selection = [I18n.t("page.none_of_the_above")]
        expect(question).to be_valid
        expect(question.errors[:selection]).to be_empty
      end

      it "returns invalid with both an item and none selected" do
        question.selection = ["option 1", I18n.t("page.none_of_the_above")]
        expect(question).not_to be_valid
        expect(question.errors[:selection]).to include(I18n.t("activemodel.errors.models.question/selection.attributes.selection.both_none_and_value_selected"))
      end

      it "does not include '(optional)' in the question text" do
        expect(question.question_text_with_optional_suffix).to eq(question.question_text)
      end

      context "when selection has a value" do
        before do
          question.selection = %w[something]
        end

        it "shows the answer" do
          expect(question.show_answer).to eq("something")
        end

        it "shows the answer in show_answer_in_csv" do
          expect(question.show_answer_in_csv).to eq(Hash[question_text, "something"])
        end
      end
    end
  end

  context "when the selection question is a radio button" do
    let(:only_one_option) { "true" }
    let(:is_optional) { false }

    before do
      question.selection = ""
    end

    it_behaves_like "a question model"

    context "when selection is blank" do
      before do
        question.selection = ""
      end

      it "returns invalid" do
        expect(question).not_to be_valid
        expect(question.errors[:selection]).to include(I18n.t("activemodel.errors.models.question/selection.attributes.selection.blank"))
      end

      it "shows as a blank string" do
        expect(question.show_answer).to eq ""
      end

      it "returns a hash with an blank value for show_answer_in_csv" do
        expect(question.show_answer_in_csv).to eq(Hash[question_text, ""])
      end
    end

    context "when selection has a value" do
      before do
        question.selection = %w[something]
      end

      it "shows the answer" do
        expect(question.show_answer).to eq(%w[something])
      end

      it "shows the answer in show_answer_in_csv" do
        expect(question.show_answer_in_csv).to eq(Hash[question_text, %w[something]])
      end
    end

    it "returns invalid when selection is not one of the options" do
      question.selection = "option 1000"
      expect(question).not_to be_valid
      expect(question.errors[:selection]).to include(I18n.t("activemodel.errors.models.question/selection.attributes.selection.inclusion"))
    end

    it "returns valid with one item selected" do
      question.selection = "option 1"
      expect(question).to be_valid
      expect(question.errors[:selection]).to be_empty
    end

    it "calculates allow_multiple_answers correctly" do
      expect(question.allow_multiple_answers?).to be false
    end

    context "when question is optional" do
      let(:is_optional) { true }

      it "returns valid with none of the above selected" do
        question.selection = I18n.t("page.none_of_the_above")
        expect(question).to be_valid
        expect(question.errors[:selection]).to be_empty
      end

      context "when selection is blank" do
        before do
          question.selection = ""
        end

        it "returns invalid" do
          expect(question).not_to be_valid
          expect(question.errors[:selection]).to include(I18n.t("activemodel.errors.models.question/selection.attributes.selection.blank"))
        end

        it "shows as a blank string" do
          expect(question.show_answer).to eq ""
        end

        it "returns a hash with an blank value for show_answer_in_csv" do
          expect(question.show_answer_in_csv).to eq(Hash[question_text, ""])
        end
      end

      context "when selection has a value" do
        before do
          question.selection = %w[something]
        end

        it "shows the answer" do
          expect(question.show_answer).to eq(%w[something])
        end

        it "shows the answer in show_answer_in_csv" do
          expect(question.show_answer_in_csv).to eq(Hash[question_text, %w[something]])
        end
      end
    end
  end

  describe "#selection_options_with_none_of_the_above" do
    let(:only_one_option) { "true" }
    let(:none_of_the_above_option) { OpenStruct.new(name: I18n.t("page.none_of_the_above")) }

    context "when the user can select 'None of the above'" do
      let(:is_optional) { true }

      it "includes the selection options" do
        question.answer_settings.each do |option|
          expect(question.selection_options_with_none_of_the_above).to include(option)
        end
      end

      it "includes 'None of the above'" do
        expect(question.selection_options_with_none_of_the_above).to include(none_of_the_above_option)
      end
    end

    context "when the user cannot select 'None of the above'" do
      let(:is_optional) { false }

      it "includes the selection options" do
        question.answer_settings.selection_options.each do |option|
          expect(question.selection_options_with_none_of_the_above).to include(option)
        end
      end

      it "does not include 'None of the above'" do
        expect(question.selection_options_with_none_of_the_above).not_to include(none_of_the_above_option)
      end
    end
  end
end
