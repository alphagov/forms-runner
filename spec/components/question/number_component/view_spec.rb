require "rails_helper"

RSpec.describe Question::NumberComponent::View, type: :component do
  let(:question_page) { build :page, answer_type: "number" }
  let(:answer_text) { nil }
  let(:question) { DataStruct.new(number: answer_text, question_text: question_page.question_text, hint_text: question_page.hint_text, answer_settings: nil) }
  let(:extra_question_text_suffix) { nil }
  let(:form_builder) do
    GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                  ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})
  end

  before do
    render_inline(described_class.new(form_builder:, question:, extra_question_text_suffix:))
  end

  describe "when component is number field" do
    it "renders the question text as a heading" do
      expect(page.find("h1")).to have_text(question.question_text)
    end

    it "renders a text input field" do
      expect(page).to have_css("input[type='text'][name='form[number]']")
    end

    context "when the user has provided an answer" do
      let(:answer_text) { 8 }

      it "sets the field value" do
        expect(page.find("input[type='text'][name='form[number]']").value).to eq answer_text.to_s
      end
    end

    context "when the question has hint text" do
      let(:question_page) { build :page, :with_hints, answer_type: "number" }

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
      let(:question_page) { build :page, answer_type: "number", question_text: "What is your name? <script>alert(\"Hi\")</script>" }
      let(:extra_question_text_suffix) { "<span>Some trusted html</span>" }

      it "returns the escaped title with the optional suffix" do
        expected_output = "What is your name? &lt;script&gt;alert(\"Hi\")&lt;/script&gt; <span>Some trusted html</span>"
        expect(page.find("h1 .govuk-label").native.inner_html).to eq(expected_output)
      end
    end
  end
end
