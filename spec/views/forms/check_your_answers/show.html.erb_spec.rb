require "rails_helper"

describe "forms/check_your_answers/show.html.erb" do
  let(:form) { build :form, :with_support, id: 1, declaration_text: }
  let(:support_details) { OpenStruct.new(email: form.support_email) }
  let(:context) { OpenStruct.new(form:) }
  let(:full_width) { false }
  let(:declaration_text) { nil }
  let(:email_confirmation_input) { build :email_confirmation_input }
  let(:rows) do
    [
      { key: { text: "Do you want to remain anonymous?" },
        value: { text: "Yes" },
        actions: [{ href: "/change", visually_hidden_text: "Do you want to remain anonymous?" }] },
    ]
  end

  before do
    assign(:current_context, context)
    assign(:mode, OpenStruct.new(preview_draft?: false, preview_archived?: false, preview_live?: false))
    assign(:form_submit_path, "/")
    assign(:full_width, full_width)
    assign(:rows, rows)
    assign(:support_details, support_details)
    render template: "forms/check_your_answers/show", locals: { email_confirmation_input: }
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

  it "displays the email confirmation form at two-thirds width" do
    expect(rendered).not_to have_css(".govuk-grid-column-full input[type='radio']")
    expect(rendered).to have_css(".govuk-grid-column-two-thirds-from-desktop input[type='radio']")
  end

  context "when full_width is true" do
    let(:full_width) { true }

    it "displays the summary list full width" do
      expect(rendered).not_to have_css(".govuk-grid-column-two-thirds-from-desktop .govuk-summary-list")
      expect(rendered).to have_css(".govuk-grid-column-full .govuk-summary-list")
    end

    it "displays the title at two-thirds width" do
      expect(rendered).not_to have_css(".govuk-grid-column-full h1")
      expect(rendered).to have_css(".govuk-grid-column-two-thirds-from-desktop h1")
    end

    it "displays the email confirmation form at two-thirds width" do
      expect(rendered).not_to have_css(".govuk-grid-column-full input[type='radio']")
      expect(rendered).to have_css(".govuk-grid-column-two-thirds-from-desktop input[type='radio']")
    end
  end

  it "contains a hidden notify reference for the confirmation email" do
    expect(rendered).to have_field("confirmation-email-reference", type: "hidden", with: email_confirmation_input.confirmation_email_reference)
  end

  it "displays the help link" do
    expect(rendered).to have_text(I18n.t("support_details.get_help_with_this_form"))
  end

  describe "email confirmation" do
    it "renders an email confirmation form" do
      expect(rendered).to have_css "form .govuk-fieldset", text: "Do you want to get an email confirming your form has been submitted?"
    end

    it "displays the email radio buttons" do
      expect(rendered).to have_text(I18n.t("helpers.legend.email_confirmation_input.send_confirmation"))
      expect(rendered).to have_field(I18n.t("helpers.label.email_confirmation_input.send_confirmation_options.send_email"))
      expect(rendered).to have_field(I18n.t("helpers.label.email_confirmation_input.send_confirmation_options.skip_confirmation"))
    end

    it "displays the email field" do
      expect(rendered).to have_field(
        I18n.t("helpers.label.email_confirmation_input.confirmation_email_address"),
        type: "email",
      )
    end

    it "email field has correct atttributes set" do
      expect(rendered).to have_selector("input[name='email_confirmation_input[confirmation_email_address]'][autocomplete='email'][spellcheck='false']")
    end

    context "when there is an error" do
      let(:email_confirmation_input) do
        email_confirmation_input = build(:email_confirmation_input)
        email_confirmation_input.validate
        email_confirmation_input
      end

      it "renders an error message" do
        expect(rendered).to have_text "Select yes if you want to get an email confirming your form has been submitted"
      end

      it "renders an error summary" do
        expect(rendered).to have_css ".govuk-error-summary"
      end

      it "links from the error summary to the first radio button" do
        page = Capybara.string(rendered.html)
        error_summary_link = page.find_link "Select yes if you want to get an email confirming your form has been submitted"
        first_radio_button = page.first :field, type: :radio

        expect(error_summary_link["href"]).to eq "##{first_radio_button['id']}"
      end
    end
  end

  # TODO: add view tests for playing back questions and Answers
end
