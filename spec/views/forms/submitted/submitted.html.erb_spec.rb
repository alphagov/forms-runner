require "rails_helper"

describe "forms/submitted/submitted.html.erb" do
  let(:form) { build :form, id: 1, what_happens_next_markdown: }
  let(:what_happens_next_markdown) { nil }
  let(:email_sent) { false }

  before do
    assign(:mode, OpenStruct.new(preview_draft?: false, preview_live?: false))

    assign(:current_context, OpenStruct.new(form:))

    render template: "forms/submitted/submitted", locals: { email_sent: }
  end

  it "contains a green govuk panel with success message " do
    expect(rendered).to have_css("h1.govuk-panel__title", text: "Your form has been submitted")
  end

  context "when the form has extra information about what happens next" do
    let(:what_happens_next_markdown) { "See what the day brings" }

    it "displays what happens next heading" do
      expect(rendered).to have_css("h2", text: "What happens next")
    end

    it "displays tells the user what happens next" do
      expect(rendered).to have_css("p", text: "See what the day brings")
    end
  end

  context "when the user has opted out of the confirmation email" do
    it "displays the email confirmation message" do
      expect(rendered).not_to have_css("p", text: I18n.t("form.submitted.email_sent"))
    end
  end

  context "when the user has opted into the confirmation email" do
    let(:email_sent) { true }

    it "displays the email confirmation message" do
      expect(rendered).to have_css("p", text: I18n.t("form.submitted.email_sent"))
    end
  end
end
