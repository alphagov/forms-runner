require "rails_helper"

RSpec.describe Question::Selection, type: :model do
  subject(:question) { described_class.new({}, options) }

  let(:options) { { is_optional:, answer_settings: OpenStruct.new({ allow_multiple_answers:, selection_options: [OpenStruct.new({ name: "option 1" }), OpenStruct.new({ name: "option 2" })] }) } }

  context "when the selection question is a checkbox" do
    let(:allow_multiple_answers) { "true" }
    let(:is_optional) { false }

    before do
      question.selection = []
    end

    it_behaves_like "a question model"

    it "returns invalid with blank selection" do
      question.selection = [""]
      expect(question).not_to be_valid
      expect(question.errors[:selection]).to include(I18n.t("activemodel.errors.models.question/selection.attributes.selection.checkbox_blank"))
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

      it "returns valid with none of the above selected" do
        question.selection = [:none_of_the_above.to_s]
        expect(question).to be_valid
        expect(question.errors[:selection]).to be_empty
      end

      it "returns invalid with both an item and none selected" do
        question.selection = ["option 1", :none_of_the_above.to_s]
        expect(question).not_to be_valid
        expect(question.errors[:selection]).to include(I18n.t("activemodel.errors.models.question/selection.attributes.selection.both_none_and_value_selected"))
      end
    end
  end

  context "when the selection question is a radio button" do
    let(:allow_multiple_answers) { "false" }
    let(:is_optional) { false }

    before do
      question.selection = ""
    end

    it_behaves_like "a question model"

    it "returns invalid with blank selection" do
      question.selection = ""
      expect(question).not_to be_valid
      expect(question.errors[:selection]).to include(I18n.t("activemodel.errors.models.question/selection.attributes.selection.blank"))
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
        question.selection = :none_of_the_above.to_s
        expect(question).to be_valid
        expect(question.errors[:selection]).to be_empty
      end
    end
  end
end
