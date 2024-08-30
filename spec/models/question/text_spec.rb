require "rails_helper"

RSpec.describe Question::Text, type: :model do
  subject(:question) { described_class.new({}, options) }

  let(:options) { { is_optional:, answer_settings: OpenStruct.new(input_type:), question_text: } }

  let(:is_optional) { false }

  let(:question_text) { Faker::Lorem.question }

  context "with input type set to single_line" do
    let(:input_type) { "single_line" }

    it_behaves_like "a question model"

    context "when text is blank" do
      it "returns invalid with nil text" do
        expect(question).not_to be_valid
        expect(question.errors[:text]).to include(I18n.t("activemodel.errors.models.question/text.attributes.text.blank"))
      end

      it "returns invalid with blank text" do
        question.text = ""
        expect(question).not_to be_valid
        expect(question.errors[:text]).to include(I18n.t("activemodel.errors.models.question/text.attributes.text.blank"))
      end

      it "shows as a blank string" do
        expect(question.show_answer).to eq ""
      end

      it "returns an empty hash for show_answer_in_csv" do
        expect(question.show_answer_in_csv).to eq({})
      end
    end

    context "when text has a value" do
      before do
        question.text = "some text"
      end

      it "shows the answer" do
        expect(question.show_answer).to eq("some text")
      end

      it "shows the answer in show_answer_in_csv" do
        expect(question.show_answer_in_csv).to eq(Hash[question_text, "some text"])
      end
    end

    it "returns invalid with text length over 499 characters" do
      question.text = "a" * 500
      expect(question).not_to be_valid
      expect(question.errors[:text]).to include(I18n.t("activemodel.errors.models.question/text.attributes.text.single_line_too_long"))
    end

    it "returns valid with text length under 500 characters" do
      question.text = "a" * 499
      expect(question).to be_valid
      expect(question.errors[:text]).to eq []
    end
  end

  context "with input type set to long_text" do
    let(:input_type) { "long_text" }

    it_behaves_like "a question model"

    context "when text is blank" do
      it "returns invalid with nil text" do
        expect(question).not_to be_valid
        expect(question.errors[:text]).to include(I18n.t("activemodel.errors.models.question/text.attributes.text.blank"))
      end

      it "returns invalid with blank text" do
        question.text = ""
        expect(question).not_to be_valid
        expect(question.errors[:text]).to include(I18n.t("activemodel.errors.models.question/text.attributes.text.blank"))
      end

      it "shows as a blank string" do
        expect(question.show_answer).to eq ""
      end

      it "returns an empty hash for show_answer_in_csv" do
        expect(question.show_answer_in_csv).to eq({})
      end
    end

    context "when text has a value" do
      before do
        question.text = "some text"
      end

      it "shows the answer" do
        expect(question.show_answer).to eq("some text")
      end

      it "shows the answer in show_answer_in_csv" do
        expect(question.show_answer_in_csv).to eq(Hash[question_text, "some text"])
      end
    end

    it "returns invalid with text length over 5000 characters" do
      question.text = "a" * 5000
      expect(question).not_to be_valid
      expect(question.errors[:text]).to include(I18n.t("activemodel.errors.models.question/text.attributes.text.long_text_too_long"))
    end

    it "returns valid with text length under 5000 characters" do
      question.text = "a" * rand(1..4999)
      expect(question).to be_valid
      expect(question.errors[:text]).to eq []
    end
  end
end
