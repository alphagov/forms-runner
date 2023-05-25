require "rails_helper"

describe "question/_name.html.erb" do
  let(:page) do
    build(:page,
          answer_type: "name",
          routing_conditions:,
          answer_settings:)
  end

  let(:answer_settings) { OpenStruct.new({ input_type:, title_needed: }) }
  let(:input_type) { "full_name" }
  let(:title_needed) { "false" }
  let(:routing_conditions) { [] }

  let(:question) do
    QuestionRegister.from_page(page)
  end

  let(:step) { Step.new(question:, page_id: page.id, form_id: 1, form_slug: "", next_page_slug: 2, page_slug: 1, page_number: 1, routing_conditions:) }

  let(:form) do
    GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                  ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})
  end

  before do
    assign(:mode, Mode.new("live"))
    render partial: "question/name", locals: { page: step, form: }
  end

  context "when the question needs a title" do
    let(:title_needed) { "true" }

    it "contains the correct autocomplete attribute for a title" do
      expect(rendered).to have_css("input[type='text'][autocomplete='honorific-prefix']")
    end
  end

  context "when the question does not need a title" do
    let(:title_needed) { "false" }

    it "does not contain the title field" do
      expect(rendered).not_to have_css("input[type='text'][autocomplete='honorific-prefix']")
    end
  end

  context "when the question is a full name" do
    let(:input_type) { "full_name" }

    it "contains the question" do
      expect(rendered).to have_css("h1", text: page.question_text)
    end

    it "contains the correct autocomplete attribute for a full name" do
      expect(rendered).to have_css("input[type='text'][autocomplete='name']")
    end
  end

  context "when the question is a name question with first and last name fields" do
    let(:input_type) { "first_and_last_name" }

    it "contains the question" do
      expect(rendered).to have_css("h1", text: page.question_text)
    end

    it "contains the correct autocomplete attributes for a first and last names" do
      expect(rendered).to have_css("input[type='text'][autocomplete='given-name']")
      expect(rendered).to have_css("input[type='text'][autocomplete='family-name']")
    end

    it "does not contain the autocomplete attribute for a middle name" do
      expect(rendered).not_to have_css("input[type='text'][autocomplete='additional-name']")
    end
  end

  context "when the question is a name question with first, middle and last name fields" do
    let(:input_type) { "first_middle_and_last_name" }

    it "contains the question" do
      expect(rendered).to have_css("h1", text: page.question_text)
    end

    it "contains the correct autocomplete attributes for first, middle and last names" do
      expect(rendered).to have_css("input[type='text'][autocomplete='given-name']")
      expect(rendered).to have_css("input[type='text'][autocomplete='family-name']")
      expect(rendered).to have_css("input[type='text'][autocomplete='additional-name']")
    end
  end
end
