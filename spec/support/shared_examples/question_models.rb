RSpec.shared_examples "a question model" do |_parameter|
  it "responds with text to .show_answer" do
    expect(question.show_answer).to be_kind_of(String)
  end

  it "responds with text to .show_answer_in_email" do
    expect(question.show_answer_in_email).to be_kind_of(String)
  end

  it "responds serializable_hash with a hash" do
    expect(question.serializable_hash).to be_kind_of(Hash)
  end

  it "responds to valid?" do
    expect(question.valid?).to be(true).or be(false)
  end

  it "responds to is_optional?" do
    expect(question.is_optional?).to be(true).or be(false)
  end

  it "responds to has_long_answer?" do
    expect(question.has_long_answer?).to be(true).or be(false)
  end

  describe "#question_text_with_optional_suffix" do
    let(:is_optional?) { false }

    before do
      question.question_text = "What is the meaning of life?"
      allow(question).to receive(:is_optional?).and_return(is_optional?)
    end

    it "responds to question_text_with_optional_suffix" do
      expect(question.question_text_with_optional_suffix).to eq(question.question_text)
    end

    context "when question is optional" do
      let(:is_optional?) { true }

      it "responds to question_text_with_optional_suffix" do
        if question.is_a?(Question::Selection)
          expect(question.question_text_with_optional_suffix).to eq(question.question_text)
        else
          expect(question.question_text_with_optional_suffix).to eq("#{question.question_text} #{I18n.t('page.optional')}")
        end
      end
    end
  end
end
