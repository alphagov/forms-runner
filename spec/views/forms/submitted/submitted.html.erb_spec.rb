require "rails_helper"

describe "forms/submitted/submitted.html.erb" do
  let(:form) { OpenStruct.new(id: 1, name: "Form 1", what_happens_next_text: "See what the day brings") }

  before do
    assign(:mode, OpenStruct.new(preview_draft?: false, preview_live?: false))

    assign(:current_context, OpenStruct.new(form:))
    render template: "forms/submitted/submitted"
  end

  it "contains a green govuk panel with success message " do
    expect(rendered).to have_css("h1.govuk-panel__title", text: "Your form has been submitted")
  end

  context "when the form has extra information about what happens next" do
    before do
      assign(:current_context, OpenStruct.new(form:))
      render template: "forms/submitted/submitted"
    end

    it "displays what happens next heading" do
      expect(rendered).to have_css("h2", text: "What happens next")
    end

    it "displays tells the user what happens next" do
      expect(rendered).to have_css("p.govuk-body", text: "See what the day brings")
    end
  end
end
