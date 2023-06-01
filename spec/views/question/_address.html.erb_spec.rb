require "rails_helper"

describe "question/address.html.erb" do
  let(:page) do
    build(:page,
          answer_type: "address",
          routing_conditions:,
          answer_settings:)
  end

  let(:answer_settings) { OpenStruct.new({ input_type: }) }
  let(:input_type) { OpenStruct.new({ international_address:, uk_address: }) }
  let(:international_address) { "false" }
  let(:uk_address) { "true" }

  let(:routing_conditions) { [] }

  let(:question) do
    QuestionRegister.from_page(page)
  end

  let(:step) { Step.new(question:, page:, form_id: 1, form_slug: "", next_page_slug: 2, page_slug: 1) }

  let(:form) do
    GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                  ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})
  end

  before do
    assign(:mode, Mode.new("live"))
    render partial: "question/address", locals: { page: step, form: }
  end

  context "when the question is an international address" do
    let(:international_address) { "true" }

    it "contains the question" do
      expect(rendered).to have_css("h1", text: page.question_text)
    end

    it "contains the correct autocomplete attributes for an international address" do
      expect(rendered).to have_css("textarea[autocomplete='street-address']")
      expect(rendered).to have_css("input[type='text'][autocomplete='country-name']")
    end
  end

  context "when the question is not an international address" do
    let(:international_address) { "false" }

    it "contains the question" do
      expect(rendered).to have_css("h1", text: page.question_text)
    end

    it "contains the correct autocomplete attributes for a UK address" do
      expect(rendered).to have_css("input[type='text'][autocomplete='address-line1']")
      expect(rendered).to have_css("input[type='text'][autocomplete='address-line2']")
      expect(rendered).to have_css("input[type='text'][autocomplete='address-level2']")
      expect(rendered).to have_css("input[type='text'][autocomplete='postal-code']")
    end
  end

  context "when the input type is nil" do
    let(:input_type) { nil }

    it "contains the question" do
      expect(rendered).to have_css("h1", text: page.question_text)
    end

    it "contains the correct autocomplete attributes for a UK address" do
      expect(rendered).to have_css("input[type='text'][autocomplete='address-line1']")
      expect(rendered).to have_css("input[type='text'][autocomplete='address-line2']")
      expect(rendered).to have_css("input[type='text'][autocomplete='address-level2']")
      expect(rendered).to have_css("input[type='text'][autocomplete='postal-code']")
    end
  end

  context "when the address has no answer_settings" do
    let(:answer_settings) { nil }

    it "contains the question" do
      expect(rendered).to have_css("h1", text: page.question_text)
    end

    it "contains the correct autocomplete attributes for a UK address" do
      expect(rendered).to have_css("input[type='text'][autocomplete='address-line1']")
      expect(rendered).to have_css("input[type='text'][autocomplete='address-line2']")
      expect(rendered).to have_css("input[type='text'][autocomplete='address-level2']")
      expect(rendered).to have_css("input[type='text'][autocomplete='postal-code']")
    end
  end
end
