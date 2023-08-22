require "rails_helper"

RSpec.describe Question::SelectionComponent::View, type: :component do
  let(:only_one_option) { "false" }
  let(:is_optional) { false }
  let(:answer_text) { nil }
  let(:extra_question_text_suffix) { nil }
  let(:form_builder) do
    GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                  ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})
  end

  before do
    render_inline(described_class.new(form_builder:, question:, extra_question_text_suffix:))
  end

  describe "when component is select one from a list field" do
    let(:question) { build :single_selection_question, is_optional: }

    it "renders the question text as a heading" do
      expect(page.find("legend h1")).to have_text(question.question_text)
    end

    it "contains the options" do
      expect(page).to have_css("input[type='radio'] + label", text: "Option 1")
      expect(page).to have_css("input[type='radio'] + label", text: "Option 2")
    end

    context "when the question has hint text" do
      let(:question) { build :single_selection_question, :with_hints }

      it "outputs the hint text" do
        expect(page.find(".govuk-hint")).to have_text(question.hint_text)
      end
    end

    context "when there is extra suffix to be added to heading" do
      let(:extra_question_text_suffix) { "Some extra text to add to the question text" }

      it "renders the question text and extra suffix as a heading" do
        expect(page.find("legend h1")).to have_text("#{question.question_text} #{extra_question_text_suffix}")
      end
    end

    context "with unsafe question text" do
      let(:question) { build :single_selection_question, question_text: "What is your name? <script>alert(\"Hi\")</script>" }
      let(:extra_question_text_suffix) { "<span>Some trusted html</span>" }

      it "returns the escaped title with the optional suffix" do
        expected_output = "What is your name? &lt;script&gt;alert(\"Hi\")&lt;/script&gt; <span>Some trusted html</span>"
        expect(page.find("h1").native.inner_html).to eq(expected_output)
      end
    end

    context "when question is optional" do
      let(:is_optional) { true }

      it "does a legend with only the question text in and not suffixed with '(optional)'" do
        expect(page.find("h1")).to have_text(question.question_text)
      end

      it "contains the 'None of the above' option" do
        expect(page).to have_css("input[type='radio'] + label", text: "None of the above")
      end
    end

    context "when question has guidance" do
      let(:question) { build :single_selection_question, :with_guidance }

      it "renders the question text as a legend" do
        expect(page.find("legend.govuk-fieldset__legend--m")).to have_text(question.question_text)
      end
    end
  end

  describe "when component is select multiple from a list field" do
    let(:question) { build :multiple_selection_question, is_optional: }

    it "renders the question text as a heading" do
      expect(page.find("h1")).to have_text(question.question_text)
    end

    it "contains the options" do
      expect(page).to have_css("input[type='checkbox'] + label", text: "Option 1")
      expect(page).to have_css("input[type='checkbox'] + label", text: "Option 2")
    end

    context "when the question has hint text" do
      let(:question) { build :multiple_selection_question, :with_hints }

      it "outputs the hint text" do
        expect(page.find(".govuk-hint")).to have_text(question.hint_text)
      end
    end

    context "when there is extra suffix to be added to heading" do
      let(:extra_question_text_suffix) { "Some extra text to add to the question text" }

      it "renders the question text and extra suffix as a heading" do
        expect(page.find("h1")).to have_text("#{question.question_text} #{extra_question_text_suffix}")
      end
    end

    context "with unsafe question text" do
      let(:question) { build :multiple_selection_question, question_text: "What is your name? <script>alert(\"Hi\")</script>" }
      let(:extra_question_text_suffix) { "<span>Some trusted html</span>" }

      it "returns the escaped title with the optional suffix" do
        expected_output = "What is your name? &lt;script&gt;alert(\"Hi\")&lt;/script&gt; <span>Some trusted html</span>"
        expect(page.find("h1").native.inner_html).to eq(expected_output)
      end
    end

    context "when question is optional" do
      let(:is_optional) { true }

      it "does a legend with only the question text in and not suffixed with '(optional)'" do
        expect(page.find("h1")).to have_text(question.question_text)
      end

      it "contains the 'None of the above' option" do
        expect(page).to have_css("input[type='checkbox'] + label", text: "None of the above")
      end
    end

    context "when question has guidance" do
      let(:question) { build :multiple_selection_question, :with_guidance }

      it "renders the question text as a legend" do
        expect(page.find("legend.govuk-fieldset__legend--m")).to have_text(question.question_text)
      end
    end
  end
end
