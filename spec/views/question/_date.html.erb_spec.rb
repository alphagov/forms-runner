require "rails_helper"

describe "question/date.html.erb" do
  let(:page) do
    Page.new({
      id: 1,
      question_text: "What is the date?",
      question_short_name: nil,
      hint_text: nil,
      answer_type: "date",
      is_optional: false,
      answer_settings: OpenStruct.new({ input_type: }),
    })
  end

  let(:input_type) { nil }

  let(:question) do
    QuestionRegister.from_page(page)
  end

  let(:step) { Step.new(question:, page_id: page.id, form_id: 1, form_slug: "", next_page_slug: 2, page_slug: 1, page_number: 1) }

  let(:form) do
    GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                  ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})
  end

  before do
    render partial: "question/date", locals: { page: step, form: }
  end

  context "when the question is a date of birth" do
    let(:input_type) { "date_of_birth" }

    it "contains the question" do
      expect(rendered).to have_css("h1", text: page.question_text)
    end

    it "contains the autocomplete attributes" do
      expect(rendered).to have_css("input[type='text'][autocomplete='bday-day']")
      expect(rendered).to have_css("input[type='text'][autocomplete='bday-month']")
      expect(rendered).to have_css("input[type='text'][autocomplete='bday-year']")
    end
  end

  context "when the question is an other date" do
    let(:input_type) { "other_date" }

    it "contains the question" do
      expect(rendered).to have_css("h1", text: page.question_text)
    end

    it "does not contain autocomplete attributes" do
      expect(rendered).to have_css("input[type='text']:not([autocomplete='bday-day'])")
      expect(rendered).to have_css("input[type='text']:not([autocomplete='bday-month'])")
      expect(rendered).to have_css("input[type='text']:not([autocomplete='bday-year'])")
    end
  end

  context "when the question is nil" do
    let(:input_type) { nil }

    it "contains the question" do
      expect(rendered).to have_css("h1", text: page.question_text)
    end

    it "does not contain autocomplete attributes" do
      expect(rendered).to have_css("input[type='text']:not([autocomplete='bday-day'])")
      expect(rendered).to have_css("input[type='text']:not([autocomplete='bday-month'])")
      expect(rendered).to have_css("input[type='text']:not([autocomplete='bday-year'])")
    end
  end
end
