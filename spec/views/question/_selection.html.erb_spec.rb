require "rails_helper"

describe "question/_selection.html.erb" do
  let(:page) do
    Page.new({
      id: 1,
      question_text: "Which city do you live in?",
      question_short_name: nil,
      hint_text: nil,
      answer_type: "selection",
      is_optional:,
      answer_settings: OpenStruct.new({ allow_multiple_answers:, selection_options: [OpenStruct.new({ name: "Bristol" }), OpenStruct.new({ name: "London" }), OpenStruct.new({ name: "Manchester" })] }),
    })
  end

  let(:question) do
    QuestionRegister.from_page(page)
  end

  let(:step) { Step.new(question:, page_id: page.id, form_id: 1, form_slug: "", next_page_slug: 2, page_slug: 1, page_number: 1) }

  let(:form) do
    GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                  ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})
  end

  before do
    render partial: "question/selection", locals: { page: step, form: }
  end

  context "when the question allows multiple answers" do
    let(:allow_multiple_answers) { "true" }

    context "when the question is not optional" do
      let(:is_optional) { false }

      it "contains the question" do
        expect(rendered).to have_css("h1", text: "Which city do you live in?")
      end

      it "contains the options" do
        expect(rendered).to have_css("input[type='checkbox'] + label", text: "Bristol")
        expect(rendered).to have_css("input[type='checkbox'] + label", text: "London")
        expect(rendered).to have_css("input[type='checkbox'] + label", text: "Manchester")
      end

      it "does not contain the 'None of the above' option" do
        expect(rendered).not_to have_css("input[type='checkbox'] + label", text: "None of the above")
      end
    end

    context "when the question is optional" do
      let(:is_optional) { true }

      it "contains the question" do
        expect(rendered).to have_css("h1", text: "Which city do you live in?")
      end

      it "contains the options" do
        expect(rendered).to have_css("input[type='checkbox'] + label", text: "Bristol")
        expect(rendered).to have_css("input[type='checkbox'] + label", text: "London")
        expect(rendered).to have_css("input[type='checkbox'] + label", text: "Manchester")
      end

      it "contains the 'None of the above' option" do
        expect(rendered).to have_css("input[type='checkbox'] + label", text: "None of the above")
      end
    end
  end

  context "when the question does not allow multiple answers" do
    let(:allow_multiple_answers) { "false" }

    context "when the question is not optional" do
      let(:is_optional) { false }

      it "contains the question" do
        expect(rendered).to have_css("h1", text: "Which city do you live in?")
      end

      it "contains the options" do
        expect(rendered).to have_css("input[type='radio'] + label", text: "Bristol")
        expect(rendered).to have_css("input[type='radio'] + label", text: "London")
        expect(rendered).to have_css("input[type='radio'] + label", text: "Manchester")
      end

      it "does not contain the 'None of the above' option" do
        expect(rendered).not_to have_css("input[type='radio'] + label", text: "None of the above")
      end
    end

    context "when the question is optional" do
      let(:is_optional) { true }

      it "contains the question" do
        expect(rendered).to have_css("h1", text: "Which city do you live in?")
      end

      it "contains the options" do
        expect(rendered).to have_css("input[type='radio'] + label", text: "Bristol")
        expect(rendered).to have_css("input[type='radio'] + label", text: "London")
        expect(rendered).to have_css("input[type='radio'] + label", text: "Manchester")
      end

      it "contains the 'None of the above' option" do
        expect(rendered).to have_css("input[type='radio'] + label", text: "None of the above")
      end
    end
  end
end
