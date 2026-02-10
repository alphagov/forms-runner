require "rails_helper"

describe "forms/email_confirmation/show.html.erb" do
  let(:form) { build :form, :with_support, id: 1 }
  let(:support_details) { OpenStruct.new(email: form.support_email) }
  let(:context) { OpenStruct.new(form:) }
  let(:email_confirmation_input) { build :email_confirmation_input }
  let(:signed_in_email) { nil }

  before do
    assign(:current_context, context)
    assign(:mode, Mode.new("form"))
    assign(:save_path, "/")
    assign(:form, form)
    assign(:support_details, support_details)
    assign(:signed_in_email, signed_in_email)
    assign(:email_confirmation_input, email_confirmation_input)
    render template: "forms/email_confirmation/show"
  end

  it "renders an email confirmation form" do
    expect(rendered).to have_css "form .govuk-fieldset", text: I18n.t("form.email_confirmation.title")
    expect(rendered).not_to have_css("h1.govuk-heading-l", text: I18n.t("form.email_confirmation.title"))
  end

  it "displays the email radio buttons" do
    expect(rendered).to have_field(I18n.t("helpers.label.email_confirmation_input.send_confirmation_options.send_email_with_answers"))
    expect(rendered).to have_field(I18n.t("helpers.label.email_confirmation_input.send_confirmation_options.send_email"))
    expect(rendered).to have_field(I18n.t("helpers.label.email_confirmation_input.send_confirmation_options.skip_confirmation"))
  end

  it "displays the email field" do
    expect(rendered).to have_field(
      I18n.t("helpers.label.email_confirmation_input.confirmation_email_address"),
      type: "email",
    )
  end

  it "contains a hidden notify reference for the confirmation email" do
    expect(rendered).to have_field("confirmation-email-reference", type: "hidden", with: email_confirmation_input.confirmation_email_reference)
  end

  it "shows the GOV.UK One Login sign in button when not signed in" do
    expect(rendered).to have_button(I18n.t("form.check_your_answers.sign_in_with_govuk_one_login"))
  end

  it "shows the GOV.UK One Login sign in button in the send answers option" do
    sign_in_text = I18n.t("form.email_confirmation.sign_in_to_get_answers_copy")
    sign_in_button_text = I18n.t("form.check_your_answers.sign_in_with_govuk_one_login")

    expect(rendered).to have_css(".govuk-radios__conditional", text: sign_in_text)
    expect(rendered).to have_css(".govuk-radios__conditional .govuk-button", text: sign_in_button_text)
    expect(rendered).to have_css(
      ".govuk-radios__conditional .govuk-button[formaction='/auth/govuk_one_login'][formmethod='post']",
      text: sign_in_button_text,
    )
  end

  context "when signed in with GOV.UK One Login" do
    let(:signed_in_email) { "person@example.gov.uk" }

    it "shows the signed in email address" do
      expect(rendered).to have_text(I18n.t("form.check_your_answers.logged_in_as", email: signed_in_email))
    end

    it "does not show the GOV.UK One Login sign in button" do
      expect(rendered).not_to have_button(I18n.t("form.check_your_answers.sign_in_with_govuk_one_login"))
    end
  end
end
