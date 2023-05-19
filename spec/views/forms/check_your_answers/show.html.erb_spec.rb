require "rails_helper"

describe "forms/check_your_answers/show.html.erb" do
  let(:form) { OpenStruct.new(id: 1, name: "Form 1") }
  let(:context) { OpenStruct.new(form:, form_id: 1, form_slug: "slug", mode: "", name: "Form 1") }
  let(:full_width) { false }

  before do
    assign(:current_context, context)
    assign(:mode, OpenStruct.new(preview_draft?: false, preview_live?: false))
    assign(:form_submit_path, "/")
    assign(:full_width, full_width)
    render template: "forms/check_your_answers/show"
  end

  context "when the form does not have a declaration" do
    let(:form) { OpenStruct.new(id: 1, name: "Form 1", declaration_text: nil) }

    it "does not display the declaration heading" do
      expect(rendered).not_to have_css("h2", text: "Declaration")
    end
  end

  context "when the form has a declaration" do
    let(:form) { OpenStruct.new(id: 1, name: "Form 1", declaration_text: "You should agree to all terms before submitting") }

    it "displays the declaration heading" do
      expect(rendered).to have_css("h2", text: "Declaration")
    end

    it "displays declaration text" do
      expect(rendered).to have_css("p.govuk-body", text: "You should agree to all terms before submitting")
    end
  end

  it "displays two-thirds" do
    expect(rendered).to have_css(".govuk-grid-column-two-thirds-from-desktop")
  end

  context "when full_width not set" do
    let(:full_width) { true }

    it "displays full width when set" do
      expect(rendered).to have_css(".govuk-grid-column-full")
    end
  end

  it "contains a hidden notify reference" do
    expect(rendered).to have_css("input", id: "notification-id", visible: :hidden)
  end
end
