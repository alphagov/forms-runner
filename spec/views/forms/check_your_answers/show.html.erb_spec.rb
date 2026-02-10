require "rails_helper"

describe "forms/check_your_answers/show.html.erb" do
  let(:form) { build :form, :with_support, id: 1, declaration_text: }
  let(:support_details) { OpenStruct.new(email: form.support_email) }
  let(:context) { OpenStruct.new(form:) }
  let(:full_width) { false }
  let(:declaration_text) { nil }
  let(:email_confirmation_summary) { I18n.t("form.check_your_answers.email_confirmation_none_summary") }
  let(:question) { build :text, question_text: "Do you want to remain anonymous?", text: "Yes" }
  let(:steps) { [build(:step, question:, page: build(:page, :with_text_settings))] }

  before do
    assign(:current_context, context)
    assign(:mode, Mode.new("form"))
    assign(:form_submit_path, "/")
    assign(:full_width, full_width)
    assign(:steps, steps)
    assign(:form, form)
    assign(:support_details, support_details)
    assign(:email_confirmation_summary, email_confirmation_summary)
    render template: "forms/check_your_answers/show"
  end

  context "when the form does not have a declaration" do
    let(:declaration_text) { nil }

    it "does not display the declaration heading" do
      expect(rendered).not_to have_css("h2", text: "Declaration")
    end
  end

  context "when the form has a declaration" do
    let(:declaration_text) { "You should agree to all terms before submitting" }

    it "displays the declaration heading" do
      expect(rendered).to have_css("h2", text: "Declaration")
    end

    it "displays declaration text" do
      expect(rendered).to have_css("p", text: form.declaration_text)
    end
  end

  it "displays the summary list two-thirds width" do
    expect(rendered).not_to have_css(".govuk-grid-column-full .govuk-summary-list")
    expect(rendered).to have_css(".govuk-grid-column-two-thirds-from-desktop .govuk-summary-list")
  end

  it "displays the title at two-thirds width" do
    expect(rendered).not_to have_css(".govuk-grid-column-full h1")
    expect(rendered).to have_css(".govuk-grid-column-two-thirds-from-desktop h1")
  end

  it "displays the selected email confirmation summary" do
    expect(rendered).to have_text(email_confirmation_summary)
  end

  it "displays the help link" do
    expect(rendered).to have_text(I18n.t("support_details.get_help_with_this_form"))
  end
end
